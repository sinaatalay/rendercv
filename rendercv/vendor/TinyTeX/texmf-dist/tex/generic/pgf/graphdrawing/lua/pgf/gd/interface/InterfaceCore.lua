-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



---
-- This class provides the core functionality of the interface between
-- all the different layers (display layer, binding layer, and
-- algorithm layer). The two classes |InterfaceToAlgorithms| and
-- |InterfaceToDisplay| use, in particular, the data structures
-- provided by this class.
--
-- @field binding This field stores the ``binding''. The graph drawing
-- system is ``bound'' to the display layer through such a binding (a
-- subclass of |Binding|). Such a binding can be thought of as a
-- ``driver'' in operating systems terminology: It is a small set of
-- functions needed to adapt the functionality to one specific display
-- system. Note that the whole graph drawing scope is bound to exactly
-- one display layer; to use several bindings you need to setup a
-- completely new Lua instance.
--
-- @field scopes This is a stack of graph drawing scopes. All
-- interface methods refer to the top of this stack.
--
-- @field collection_kinds This table stores which collection kinds
-- have been defined together with their properties.
--
-- @field algorithm_classes A table that maps algorithm keys (like
-- |tree layout| to class objects).
--
-- @field keys A lookup table of all declared keys. Each entry of this
-- table consists of the original entry passed to the |declare|
-- method. Each of these tables is both index at a number (so you can
-- iterate over it using |ipairs|) and also via the key's name.

local InterfaceCore = {
  -- The main binding. Set by |InterfaceToDisplay.bind| method.
  binding             = nil,

  -- The stack of Scope objects.
  scopes              = {},

  -- The collection kinds.
  collection_kinds    = {},

  -- The algorithm classes
  algorithm_classes   = {},

  -- The declared keys
  keys                = {},

  -- The phase kinds
  phase_kinds         = {},

  -- Internals for handling the options stack
  option_stack        = {},
  option_cache_height = nil,
  option_initial      = {
    algorithm_phases = {
      ["preprocessing stack"] = {},
      ["edge routing stack"] = {},
      ["postprocessing stack"] = {},
    }
  },
  option_aliases      = {
    [{}] = true -- Remove, once Lua Link Bug is fixed
  },

  -- Constant strings for special collection kinds.
  sublayout_kind      = "INTERNAL_sublayout_kind",
  subgraph_node_kind  = "INTERNAL_subgraph_node_kind",
}

-- Namespace
require("pgf.gd.interface").InterfaceCore = InterfaceCore


InterfaceCore.option_initial.__index = InterfaceCore.option_initial
InterfaceCore.option_initial.algorithm_phases.__index = InterfaceCore.option_initial.algorithm_phases


-- Imports
local Coordinate = require "pgf.gd.model.Coordinate"


--- Returns the top scope
--
-- @return The current top scope, which is the scope in which
--         everything should happen right now.

function InterfaceCore.topScope()
  return assert(InterfaceCore.scopes[#InterfaceCore.scopes], "no graph drawing scope open")
end



local factors = {
  cm=28.45274,
  mm=2.84526,
  pt=1.0,
  bp=1.00374,
  sp=0.00002,
  pc=12.0,
  em=10,
  ex=4.30554,
  ["in"]=72.27,
  dd=1.07,
  cc=12.8401,
  [""]=1,
}

local time_factors = {
  s=1,
  ms=0.001,
  min=60,
  h=3600
}

local directions = {
  down = -90,
  up = 90,
  left = 180,
  right = 0,
  south = -90,
  north = 90,
  west = 180,
  east = 0,
  ["north east"] = 45,
  ["north west"] = 135,
  ["south east"] = -45,
  ["south west"] = -135,
  ["-"] = 0,
  ["|"] = -90,
}

---
-- Converts parameters types. This method is used by both the
-- algorithm layer as well as the display layer to convert strings
-- into the different types of parameters. When a parameter
-- is pushed onto the option stack, you can either provide a value of
-- the parameter's type; but you can also provide a string. This
-- string can then be converted by this function to a value of the
-- correct type.
--
-- @param s A parameter value or a string.
-- @param t The type of the parameter
--
-- @return If |s| is not a string, it is just returned. If it is a
-- string, it is converted to the type |t|.

function InterfaceCore.convert(s,t)
  if type(s) ~= "string" then
    return s
  elseif t == "number" then
    return tonumber(s)
  elseif t == "length" then
    local num, dim = string.match(s, "([%d.]+)(.*)")
    return tonumber(num) * assert(factors[dim], "unknown unit")
  elseif t == "time" then
    local num, dim = string.match(s, "([%d.]+)(.*)")
    return tonumber(num) * assert(time_factors[dim], "unknown time unit")
  elseif t == "string" then
    return s
  elseif t == "canvas coordinate" or t == "coordinate" then
    local x, y = string.match(s,"%(([%d.]+)pt,([%d.]+)pt%)")
    return Coordinate.new(tonumber(x),tonumber(y))
  elseif t == "boolean" then
    return s == "true"
  elseif t == "raw" then
    return loadstring(s)()
  elseif t == "direction" then
    return directions[s] or tonumber(s)
  elseif t == "nil" or t == nil then
    return nil
  else
    error ("unknown parameter type")
  end
end


-- Done

return InterfaceCore
