-----------------------------------------------------------------------
--         FILE:  luaotfload-szss.lua
--  DESCRIPTION:  part of luaotfload / szss
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-szss",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / Special feature handling",
    license       = "GPL v2.0",
    author        = "Marcel Krüger"
}

local direct       = node.direct
local otfregister  = fonts.constructors.features.otf.register

local copy         = direct.copy
local getdisc      = direct.getdisc
local getnext      = direct.getnext
local insert_after = direct.insert_after
local is_char      = direct.is_char
local setchar      = direct.setchar
local setdisc      = direct.setdisc

local disc_t       = node.id'disc'

local szsstable = setmetatable({}, { __index = function(t, i)
  local v = font.getfont(i)
  v = v and v.properties
  v = v and v.transform_sz or false
  t[i] = v
  return v
end})

local function szssinitializer(tfmdata, value, features)
  if value == 'auto' then
    value = not tfmdata.characters[0x1E9E]
  end
  local properties = tfmdata.properties
  properties.transform_sz = value
end

local function szssprocessor(head,font) -- ,attr,direction)
  if not szsstable[font] then return end
  local n = head
  while n do
    local c, id = is_char(n, font)
    if c == 0x1E9E then
      setchar(n, 0x53)
      head, n = insert_after(head, n, copy(n))
    elseif id == disc_t then
      local pre, post, replace = getdisc(n)
      pre = szssprocessor(pre, font)
      post = szssprocessor(post, font)
      replace = szssprocessor(replace, font)
      setdisc(n, pre, post, replace)
    end
    n = getnext(n)
  end
  return head
end

otfregister {
  name = 'szss',
  description = 'Replace capital ß with SS',
  default = 'auto',
  initializers = {
    node = szssinitializer,
    plug = szssinitializer,
  },
  processors = {
    position = 1,
    node = szssprocessor,
    plug = szssprocessor,
  },
}

-- harf-only features (for node they are implemented in the fontloader

otfregister {
  name = 'extend',
  description = 'Fake extend',
  default = false,
  manipulators = {
    plug = function(tfmdata, _, value)
      value = tonumber(value)
      if not value then
        error[[Invalid extend value]]
      end
      tfmdata.extend = value * 1000
      tfmdata.hb.hscale = tfmdata.units_per_em * value
      tfmdata.hb.space = tfmdata.hb.space * value
      local parameters = tfmdata.parameters
      parameters.slant = parameters.slant * value
      parameters.space = parameters.space * value
      parameters.space_stretch = parameters.space_stretch * value
      parameters.space_shrink = parameters.space_shrink * value
      parameters.quad = parameters.quad * value
      parameters.extra_space = parameters.extra_space * value
      local done = {}
      for _, char in next, tfmdata.characters do
        if char.width and not done[char] then
          char.width = char.width * value
          done[char] = true
        end
      end
    end,
  },
}

otfregister {
  name = 'slant',
  description = 'Fake slant',
  default = false,
  manipulators = {
    plug = function(tfmdata, _, value)
      value = tonumber(value)
      if not value then
        error[[Invalid slant value]]
      end
      tfmdata.slant = value * 1000
      local parameters = tfmdata.parameters
      parameters.slant = parameters.slant + value * 65536
    end,
  },
}

otfregister {
  name = 'squeeze',
  description = 'Fake squeeze',
  default = false,
  manipulators = {
    plug = function(tfmdata, _, value)
      value = tonumber(value)
      if not value then
        error[[Invalid squeeze value]]
      end
      tfmdata.squeeze = value * 1000
      tfmdata.hb.vscale = tfmdata.units_per_em * value
      local parameters = tfmdata.parameters
      parameters.slant = parameters.slant / value
      parameters.x_height = parameters.x_height * value
      parameters[8] = parameters[8] * value
      local done = {}
      for _, char in next, tfmdata.characters do
        if not done[char] then
          if char.height then
            char.height = char.height * value
          end
          if char.depth then
            char.depth = char.depth * value
          end
          done[char] = true
        end
      end
    end,
  },
}

-- Legacy TeX Input Method Disguised as Font Ligatures hack.
--
-- Single replacements, keyed by character to replace. Handled separately
-- because TeX ligaturing mechanism does not support one-to-one replacements.
local trep = {
  [0x0022] = 0x201D, -- ["]
  [0x0027] = 0x2019, -- [']
  [0x0060] = 0x2018, -- [`]
}

-- Ligatures. The value is a character "ligature" table as described in the
-- manual.
local tlig ={
  [0x2013] = { [0x002D] = { char = 0x2014 } }, -- [---]
  [0x002D] = { [0x002D] = { char = 0x2013 } }, -- [--]
  [0x0060] = { [0x0060] = { char = 0x201C } }, -- [``]
  [0x0027] = { [0x0027] = { char = 0x201D } }, -- ['']
  [0x0021] = { [0x0060] = { char = 0x00A1 } }, -- [!`]
  [0x003F] = { [0x0060] = { char = 0x00BF } }, -- [?`]
  [0x002C] = { [0x002C] = { char = 0x201E } }, -- [,,]
  [0x003C] = { [0x003C] = { char = 0x00AB } }, -- [<<]
  [0x003E] = { [0x003E] = { char = 0x00BB } }, -- [>>]
}

local function tligprocessor(head, font)
  local n = head
  while n do
    local c, id = is_char(n, font)
    local rep = trep[c]
    if rep then
      setchar(n, rep)
    elseif id == disc_t then
      local pre, post, replace = getdisc(n)
      tligprocessor(pre, font)
      tligprocessor(post, font)
      tligprocessor(replace, font)
    end
    n = getnext(n)
  end
end

otfregister {
  name = 'tlig',
  description = 'Traditional TeX ligatures',
  default = false,
  manipulators = {
    plug = function(tfmdata, _, value)
      local characters = tfmdata.characters
      for codepoint, ligatures in next, tlig do
        local char = characters[codepoint]
        if char then
          char.ligatures = ligatures
        end
      end
    end,
  },
  processors = {
    position=1,
    plug = tligprocessor,
  },
}

--- vim:sw=2:ts=2:expandtab:tw=71
