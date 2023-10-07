-- lua-uni-graphemes.lua
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

local unpack = table.unpack
local move = table.move
local codes = utf8.codes
local utf8char = utf8.char

local empty = {}
local result = {}

local casefold, casefold_lookup do
  local p = require'lua-uni-parse'
  local l = lpeg or require'lpeg'

  local data = p.parse_file('CaseFolding', l.Cf(
      l.Ct(l.Cg(l.Ct'', 'C') * l.Cg(l.Ct'', 'F') * l.Cg(l.Ct'', 'S') * l.Cg(l.Ct'', 'T'))
    * (l.Cg(p.fields(p.codepoint, l.C(1), l.Ct(p.codepoint * (' ' * p.codepoint)^0), true)) + p.eol)^0
    * -1
  , function(t, base, class, mapping)
    t[class][base] = mapping
    return t
  end))
  local C, F, S, T = data.C, data.F, data.S, data.T
  data = nil

  function casefold_lookup(c, full, special)
    return (special and T[c]) or C[c] or (full and F or S)[c]
  end
  function casefold(s, full, special)
    local first = special and T or empty
    local second = C
    local third = full and F or S
    local result = result
    for i = #result, 1, -1 do result[i] = nil end
    local i = 1
    for _, c in codes(s) do
      local datum = first[c] or second[c] or third[c]
      if datum then
        local l = #datum
        move(datum, 1, l, i, result)
        i = i + l
      else
        result[i] = c
        i = i + 1
      end
    end
    return utf8char(unpack(result))
  end
end

return {
  casefold = casefold,
  casefold_lookup = casefold_lookup,
}
