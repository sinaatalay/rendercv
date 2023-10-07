-----------------------------------------------------------------------
--         FILE:  luaotfload-suppress.lua
--  DESCRIPTION:  part of luaotfload / suppress
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-suppress",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / suppress",
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
local getfont      = font.getfont

local disc_t       = node.id'disc'

local empty        = {}

local lpeg = lpeg or require'lpeg'
local valueparser do
  local digits = lpeg.R'09'^1/tonumber
  local hexdigits = (lpeg.P'u+' + '"' + '0x') * (lpeg.R('09', 'AF', 'af')^1/function(s) return tonumber(s, 16) end)
  local entry = lpeg.Cg((hexdigits + digits) * lpeg.Cc(true))
  local sep = lpeg.P' '^0 * lpeg.S'/|,;' * lpeg.P' '^0
  valueparser = lpeg.Cf(lpeg.Ct'' * entry * (sep * entry)^0, rawset) * -1
end

local function initializer(tfmdata, value, features)
  local properties = tfmdata.properties
  properties.suppress_liga = valueparser:match(value)
  if not properties.suppress_liga then
    error[[Invalid suppress value]]
  end
end

local function processor(head,font) -- ,attr,direction)
  local supp = getfont(font).properties.suppress_liga
  if not supp then return head end
  local n = head
  while n do
    local c, id = is_char(n, font)
    if supp[c] then
      local nn = copy(n)
      setchar(nn, 0x200C)
      head, n = insert_after(head, n, nn)
    elseif id == disc_t then
      local pre, post, replace = getdisc(n)
      pre = processor(pre, font)
      post = processor(post, font)
      replace = processor(replace, font)
      setdisc(n, pre, post, replace)
    end
    n = getnext(n)
  end
  return head
end

otfregister {
  name = 'suppress',
  description = 'Insert ZWNJ to suppress ligatures',
  default = false,
  initializers = {
    -- node = initializer,
    plug = initializer,
  },
  processors = {
    position = 1,
    -- node = processor,
    plug = processor,
  },
}

--- vim:sw=2:ts=2:expandtab:tw=71
