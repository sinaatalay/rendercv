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

local property do
  local p = require'lua-uni-parse'
  local l = lpeg or require'lpeg'

  property = p.parse_file('emoji-data',
    l.Cg(p.fields(p.codepoint_range, l.C'Extended_Pictographic')) + p.ignore_line,
    p.multiset)

  property = p.parse_file('GraphemeBreakProperty', l.Cf(
      l.Carg(1)
    * (l.Cg(p.fields(p.codepoint_range, l.C(l.R('az', 'AZ', '__')^1))) + p.ignore_line)^0
    * -1, p.multiset),
    nil,
    property)
  if not property then
    error[[Break Property matching failed]]
  end
end

local controls = { CR = true, LF = true, Control = true, }
local precore_lookup = {
  Prepend = "PRECORE",
  L = "L",
  V = "V",
  LV = "V",
  LVT = "T",
  T = "T",
  Regional_Indicator = "RI",
  Extended_Pictographic = "POST_PICTO",
}
local l_lookup = {
  L = "L",
  V = "V",
  LV = "V",
  LVT = "T",
}
local postcore_map = { Extend = true, ZWJ = true, SpacingMark = true, }
local state_map state_map = {
  START = function(prop)
    if prop == 'CR' then
      return 'CR', true
    end
    if prop == 'LF' or prop == 'Control' then
      return 'START', true
    end
    return state_map.PRECORE(prop), true
  end,
  PRECORE = function(prop)
    if controls[prop] then
      return state_map.START(prop)
    end
    return precore_lookup[prop] or 'POSTCORE'
  end,
  POSTCORE = function(prop)
    if postcore_map[prop] then
      return 'POSTCORE'
    end
    return state_map.START(prop)
  end,
  RI = function(prop)
    if prop == 'Regional_Indicator' then
      return 'POSTCORE'
    end
    return state_map.POSTCORE(prop)
  end,
  PRE_PICTO = function(prop)
    if prop == "Extended_Pictographic" then
      return "POST_PICTO"
    end
    return state_map.POSTCORE(prop)
  end,
  POST_PICTO = function(prop)
    if prop == "Extend" then
      return "POST_PICTO"
    end
    if prop == "ZWJ" then
      return "PRE_PICTO"
    end
    return state_map.POSTCORE(prop)
  end,
  L = function(prop)
    local nextstate = l_lookup[prop]
    if nextstate then
      return nextstate
    end
    return state_map.POSTCORE(prop)
  end,
  V = function(prop)
    if prop == 'V' then
      return 'V'
    end
    return state_map.T(prop)
  end,
  T = function(prop)
    if prop == 'T' then
      return 'T'
    end
    return state_map.POSTCORE(prop)
  end,
  CR = function(prop)
    if prop == 'LF' then
      return 'START'
    else
      return state_map.START(prop)
    end
  end,
}

-- The value of "state" is considered internal and should not be relied upon.
-- Just pass it to the function as is or pass nil. `nil` should only be passed when the passed codepoint starts a new cluster
function read_codepoint(cp, state)
  local new_cluster
  state, new_cluster = state_map[state or 'START'](property[cp])
  return new_cluster, state
end

-- A Lua iterator for strings -- Only reporting the beginning of every grapheme cluster
local function graphemes_start(str)
  local nextcode, str, i = utf8.codes(str)
  local state = "START"
  return function()
    local new_cluster, code
    repeat
      i, code = nextcode(str, i)
      if not i then return end
      new_cluster, state = read_codepoint(code, state)
    until new_cluster
    return i, code
  end
end
-- A more useful iterator: returns the byterange of the graphemecluster in reverse order followed by a string with te cluster
local function graphemes(str)
  local iter = graphemes_start(str)
  return function(_, cur)
    if cur == #str then return end
    local new = iter()
    if not new then return #str, cur + 1, str:sub(cur + 1) end
    return new - 1, cur + 1, str:sub(cur + 1, new - 1)
  end, nil, iter() - 1
end
return {
  read_codepoint = read_codepoint,
  graphemes_start = graphemes_start,
  graphemes = graphemes,
}
--[[
for i, c in graphemes_start'äbcdef' do
  print(i, utf8.char(c))
end
for i, j, s in graphemes'Z͑ͫ̓ͪ̂ͫ̽͏̴̙̤̞͉͚̯̞̠͍A̴̵̜̰͔ͫ͗͢L̠ͨͧͩ͘G̴̻͈͍͔̹̑͗̎̅͛́Ǫ̵̹̻̝̳͂̌̌͘!͖̬̰̙̗̿̋ͥͥ̂ͣ̐́́͜͞' do
  print(j, i, s)
end
]]
