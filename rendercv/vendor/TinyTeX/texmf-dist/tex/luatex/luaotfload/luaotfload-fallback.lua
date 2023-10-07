-----------------------------------------------------------------------
--         FILE:  luaotfload-fallback.lua
--  DESCRIPTION:  part of luaotfload / fallback
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") {
    name          = "luaotfload-fallback",
    version       = "3.26",     --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / fallback",
    license       = "GPL v2.0",
    author        = "Marcel Krüger"
}

local nodenew            = node.direct.new
local getfont            = font.getfont
local setfont            = node.direct.setfont
local getwhd             = node.direct.getwhd
local insert_after       = node.direct.insert_after
local traverse_char      = node.direct.traverse_char
local protect_glyph      = node.direct.protect_glyph
local otffeatures        = fonts.constructors.newfeatures "otf"
-- local normalize          = fonts.handlers.otf.features.normalize
local definers           = fonts.definers
local define_font --     = luaotfload.define_font % This is set when the first font is loaded.

local fallback_table_fontnames = {}

local fallback_table = setmetatable({}, {
  __index = function(t, name)
    local names = fallback_table_fontnames[name]
    if not names then 
      t[name] = false
      return false
    end
    local res = setmetatable({}, {
      __index = function(tt, size)
        local lookup = {}
        for i=#names,1,-1 do
          local f = define_font(names[i] .. ';-fallback', size)
          local fid
          if type(f) == 'table' then
            fid = font.define(f)
            definers.register(f, fid)
          elseif f then
            fid = f
            f = font.getfont(fid)
          end
          lookup[-i] = f -- Needed for multiscript interactions
          for uni, _ in next, f.characters do
            rawset(lookup, uni, fid)
          end
        end
        tt[size] = lookup
        return lookup
      end,
    })
    t[name] = res
    return res
  end,
})

local fallback_lookups = setmetatable({}, {
  __index = function(t, fid)
    local f = font.getfont(fid)
    -- table.tofile('myfont2', f)
    local res = f and f.fallback_lookup or false
    if res then
      res = table.merged(res)
      for uni in next, f.characters do
        rawset(res, uni, nil)
      end
    end
    t[fid] = res
    return res
  end,
})

local function makefallbackfont(tfmdata, _, fallback)
  local t = fallback_table[fallback]
  if not t then error(string.format("Unknown fallback table %s", fallback)) end
  fallback = t[tfmdata.size]
  local fallback_lookup = {}
  tfmdata.fallback_lookup = fallback
end

local glyph_id = node.id'glyph'
-- TODO: inherited fonts (combining accents etc.)
local function dofallback(head, _, _, _, direction)
  head = node.direct.todirect(head)
  local last_fid, last_fallbacks
  for cur, cid, fid in traverse_char(head) do
    if fid ~= last_fid then
      last_fid, last_fallbacks = fid, fallback_lookups[fid]
    end
    if last_fallbacks then
      local new_fid = last_fallbacks[cid]
      if new_fid then
        setfont(cur, new_fid)
      end
    end
  end
end

function luaotfload.add_fallback(name, fonts)
  define_font = define_font or luaotfload.define_font -- Lazy loading because this file get's loaded before define_font is defined
  if fonts == nil then
    fonts = name
    name = #fallback_table_fontnames + 1
  else
    name = name:lower()
  end
  fallback_table_fontnames[name] = fonts
  fallback_table[name] = nil
  return name
end

otffeatures.register {
  name        = "fallback",
  description = "Fill in missing glyphs from other fonts",
  manipulators = {
    node = makefallbackfont,
    plug = makefallbackfont,
  },
  -- processors = { -- processors would be nice, but they are applied
  --                -- too late for our purposes
  --   node = donotdef,
  -- }
}

return {
  process = dofallback,
}
--- vim:sw=2:ts=2:expandtab:tw=71
