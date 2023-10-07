-----------------------------------------------------------------------
--         FILE:  luaotfload-unicode.lua
--  DESCRIPTION:  part of luaotfload / unicode
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") {
    name          = "luaotfload-unicode",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / Unicode helpers",
    license       = "CC0 1.0 Universal",
    author        = "Marcel Krüger"
}

local utf8codes = utf8.codes
local utf8char = utf8.char
local sub = string.sub
local unpack = table.unpack
local concat = table.concat
local move = table.move

local codepoint = lpeg.S'0123456789ABCDEF'^4/function(c)return tonumber(c, 16)end
local empty = {}
local result = {}

local alphnum_only do
  local niceentry = lpeg.Cg(codepoint * ';' * (1-lpeg.P';')^0 * ';' * lpeg.S'LN' * lpeg.Cc(true))
  local entry = niceentry^0 * (1-lpeg.P'\n')^0 * lpeg.P'\n'
  local file = lpeg.Cf(
      lpeg.Ct''
    * entry^0
  , rawset)

  local f = io.open(kpse.find_file"UnicodeData.txt")
  local data = file:match(f:read'*a')
  f:close()
  function alphnum_only(s)
    local result = result
    for i = #result, 1, -1 do result[i] = nil end
    local nice = nil
    for p, c in utf8codes(s) do
      if data[c]
          or (c >= 0x3400 and c<= 0x3DB5)
          or (c >= 0x4E00 and c<= 0x9FEF)
          or (c >= 0xAC00 and c<= 0xD7A3)
          then
        if not nice then nice = p end
      else
        if nice then
          result[#result + 1] = sub(s, nice, p-1)
          nice = nil
        end
      end
    end
    if nice then
      result[#result + 1] = sub(s, nice, #s)
    end
    return concat(result)
  end
end

local uppercase, lowercase, ccc, cased, case_ignorable, titlecase = {}, {}, {}, {}, {}, nil do
  titlecase = nil -- Not implemented yet(?)
  local ignored_field = (1-lpeg.P';')^0 * ';'
  local cased_category = lpeg.P'Ll;' + 'Lu;' + 'Lt;'
  local case_ignore_category = lpeg.P'Mn;' + 'Me;' + 'Cf;' + 'Lm;' + 'Sk;'

  local simple_entry =
      codepoint/0 * ';'
    * ignored_field -- Name
    * (ignored_field - cased_category - case_ignore_category) -- General_Category
    * '0;' -- ccc
    * ignored_field -- Bidi
    * ignored_field -- Decomp
    * ignored_field -- Numeric
    * ignored_field -- Numeric
    * ignored_field -- Numeric
    * ignored_field -- Mirrored
    * ignored_field -- Obsolete
    * ignored_field -- Obsolete
    * ';;\n'
  local entry = simple_entry
    + codepoint * ';'
    * ignored_field -- Name
    * (cased_category * lpeg.Cc(cased) + case_ignore_category * lpeg.Cc(case_ignorable) + ignored_field * lpeg.Cc(nil)) -- General_Category
    * ('0;' * lpeg.Cc(nil) + lpeg.R'09'^1/tonumber * ';') -- ccc
    * ignored_field -- Bidi
    * ignored_field -- Decomp
    * ignored_field -- Numeric
    * ignored_field -- Numeric
    * ignored_field -- Numeric
    * ignored_field -- Mirrored
    * ignored_field -- Obsolete
    * ignored_field -- Obsolete
    * (codepoint + lpeg.Cc(nil)) * ';' -- uppercase
    * (codepoint + lpeg.Cc(nil)) * ';' -- lowercase
    * (codepoint + lpeg.Cc(nil)) * '\n' -- titlecase
    / function(codepoint, cased_flag, ccc_val, upper, lower, title)
      if cased_flag then cased_flag[codepoint] = true end
      ccc[codepoint] = ccc_val
      uppercase[codepoint] = upper
      lowercase[codepoint] = lower
      -- if title then titlecase[codepoint] = title end -- Not implemented yet(?)
    end
  local file = entry^0 * -1

  local f = io.open(kpse.find_file"UnicodeData.txt")
  assert(file:match(f:read'*a'))
  f:close()
end

local props do
  local ws = lpeg.P' '^0
  local nl = ws * ('#' * (1-lpeg.P'\n')^0)^-1 * '\n'
  local entry = codepoint * (".." * codepoint + lpeg.Cc(false)) * ws * ";" * ws * lpeg.C(lpeg.R("AZ", "az", "__")^1) * nl
  local file = lpeg.Cf(
      lpeg.Ct(
          lpeg.Cg(lpeg.Ct"", "Soft_Dotted")
        * lpeg.Cg(lpeg.Cc(cased), "Other_Lowercase")
        * lpeg.Cg(lpeg.Cc(cased), "Other_Uppercase"))
    * (lpeg.Cg(entry) + nl)^0
  , function(t, cp_start, cp_end, prop)
    local prop_table = t[prop]
    if prop_table then
      for cp = cp_start, cp_end or cp_start do
        prop_table[cp] = true
      end
    end
    return t
  end) * -1

  local f = io.open(kpse.find_file"PropList.txt")
  props = file:match(f:read'*a')
  f:close()
end

do
  local ws = lpeg.P' '^0
  local nl = ws * ('#' * (1-lpeg.P'\n')^0)^-1 * '\n'
  local file = (codepoint * (".." * codepoint + lpeg.Cc(false)) * ws * ";" * ws * (lpeg.P'Single_Quote' + 'MidLetter' + 'MidNumLet') * nl / function(cp_start, cp_end)
    for cp = cp_start, cp_end or cp_start do
      case_ignorable[cp] = true
    end
  end + (1-lpeg.P'\n')^0 * '\n')^0 * -1

  local f = io.open(kpse.find_file"WordBreakProperty.txt")
  assert(file:match(f:read'*a'))
  f:close()
end

do
  local ws = lpeg.P' '^0
  local nl = ws * ('#' * (1-lpeg.P'\n')^0)^-1 * '\n'
  local empty = {}
  local function set(t, cp, condition, value)
    local old = t[cp] or cp
    if not condition then
      if #value == 1 and tonumber(old) then
        t[cp] = value[1]
        return
      end
      condition = empty
    end
    if tonumber(old or cp) then
      old = {_ = {old}}
      t[cp] = old
    end
    for i=1, #condition do
      local cond = condition[i]
      local step = old[cond]
      if not step then
        step = {}
        old[cond] = step
      end
      old = step
    end
    old._ = value
  end
  local entry = codepoint * ";"
              * lpeg.Ct((ws * codepoint)^1 + ws) * ";"
              * lpeg.Ct((ws * codepoint)^1 + ws) * ";"
              * lpeg.Ct((ws * codepoint)^1 + ws) * ";"
              * (lpeg.Ct((ws * lpeg.C(lpeg.R('AZ', 'az', '__')^1))^1) * ";")^-1
              * ws * nl / function(cp, lower, title, upper, condition)
                set(lowercase, cp, condition, lower)
                set(uppercase, cp, condition, upper)
              end
  local file = (entry + nl)^0 * -1

  local f = io.open(kpse.find_file"SpecialCasing.txt")
  assert(file:match(f:read'*a'))
  f:close()
end

do
  local function eq(a, b)
    if not a then return false end
    if not b then return false end
    if a == b then return true end
    if #a ~= #b then return false end
    for i=1,#a do if a[i] ~= b[i] then return false end end
    return true
  end
  local function collapse(t, inherited)
    inherited = t._ or inherited
    local empty = true
    for k,v in next, t do
      if k ~= '_' then
        if eq(inherited, collapse(v, inherited)) then
          t[k] = nil
        else
          empty = false
        end
      end
    end
    return empty and inherited
  end
  local function cleanup(t)
    for k,v in next, t do
      if not tonumber(v) then
        local collapsed = collapse(v)
        if collapsed and #collapsed == 1 then
          v = collapsed[1]
          if k == v then
            v = nil
          end
          t[k] = v
        end
      end
    end
  end
  cleanup(uppercase)
  cleanup(lowercase)
end

-- Here we manipulate the uppercase table a bit to add the `de-alt` language using capital eszett.
uppercase[0x00DF]['de-x-eszett'] = { _ = { 0x1E9E } }
uppercase[0x00DF]['de-alt'] = uppercase[0x00DF]['de-x-eszett']

-- Special handling for Eastern Armenian based on Unicode document L2/20-143.
uppercase[0x0587]['hy'] = { _ = { 0x0535, 0x054E } }
-- Resore Unicode behavior. This entry is redundant, but we have to be aware of it
-- if we later start to ignore unknown private use tags
uppercase[0x0587]['hy-x-yiwn'] = { _ = uppercase[0x0587]._ }

return {
  alphnum_only = alphnum_only,
  casemapping = {
    uppercase = uppercase,
    lowercase = lowercase,
    cased = cased,
    case_ignorable = case_ignorable,
    -- titlecase = titlecase,
  },
  ccc = ccc,
  soft_dotted = props.Soft_Dotted,
}
