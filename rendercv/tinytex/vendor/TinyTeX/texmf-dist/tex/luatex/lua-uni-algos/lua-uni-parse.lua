-- lua-uni-parse.lua
-- Copyright 2020--2022 Marcel Krüger
--
-- This work may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3
-- of this license or (at your option) any later version.
-- The latest version of this license is in
--   http://www.latex-project.org/lppl.txt
-- and version 1.3 or later is part of all distributions of LaTeX
-- version 2005/12/01 or later.
--
-- This work has the LPPL maintenance status `maintained'.
-- 
-- The Current Maintainer of this work is Marcel Krüger

-- Just a simple helper module to make UCD parsing more readable

local lpeg = lpeg or require'lpeg'
local R = lpeg.R
local tonumber = tonumber

local codepoint = lpeg.R('09', 'AF')^4 / function(c) return tonumber(c, 16) end
local sep = lpeg.P' '^0 * ';' * lpeg.P' '^0
local codepoint_range = codepoint * ('..' * codepoint + lpeg.Cc(false))
local ignore_line = (1-lpeg.P'\n')^0 * '\n'
local eol = lpeg.S' \t'^0 * ('#' * ignore_line + '\n')
local ignored = (1-lpeg.S';#\n')^0
local number = lpeg.R'09'^1 / tonumber

local function fields(first, ...)
  if first == ignore_line then
    assert(select('#', ...) == 0)
    return ignore_line
  end
  local tail = select('#', ...) == 0 and eol or sep * fields(...)
  return first * tail
end

local function multiset(table, key1, key2, value)
  for key = key1,(key2 or key1) do
    table[key] = value
  end
  return table
end

local function parse_uni_file(filename, patt, func, ...)
  if func then
    return parse_uni_file(filename, lpeg.Cf(lpeg.Ct'' * patt^0 * -1, func), nil, ...)
  end
  local resolved = kpse.find_file(filename .. '.txt')
  if not resolved then
    error(string.format("Unable to find Unicode datafile %q", filename))
  end
  local f = assert(io.open(resolved))
  local data = f:read'*a'
  f:close()
  return lpeg.match(patt, data, 1, ...)
end

return {
  codepoint = codepoint,
  codepoint_range = codepoint_range,
  ignore_line = ignore_line,
  ignore_field = ignored,
  eol = eol,
  sep = sep,
  number = number,
  fields = fields,
  multiset = multiset,
  parse_file = parse_uni_file,
}
