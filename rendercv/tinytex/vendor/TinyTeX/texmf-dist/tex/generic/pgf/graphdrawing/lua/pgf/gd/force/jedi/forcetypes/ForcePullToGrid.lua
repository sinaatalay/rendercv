-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--- This is a subclass of ForceTemplate, which is used to implement forces
-- that work on individual vertices and pulls them to a virtual grid with
-- cells of the size determined by the user options |grid x length| and
-- |grid y length|. The forces depend on the canvas position
-- of the vertices relative to th next grid point. This class is e.\,g.\ used
-- for the post-processing technique |snap to grid|.


-- Imports
local ForceTemplate = require "pgf.gd.force.jedi.base.ForceTemplate"
local lib = require "pgf.gd.lib"
local Preprocessing = require "pgf.gd.force.jedi.base.Preprocessing"

-- Localize math functions
local max = math.max
local sqrt = math.sqrt
local min = math.min
local floor = math.floor
local round
function round(number)
  return floor((number * 10 + 0.5) / 10)
end

-- Implementation starts here:

local ForcePullToGrid = lib.class { base_class = ForceTemplate }

function ForcePullToGrid:constructor ()
  ForceTemplate.constructor(self)
  self.p = {}
end

-- This force class works on individual vertices and only depends on their
-- current position. Thus the vertex table of the current graph is simply
-- copied to the variable |p|.
--
--  @param v The vertices of the graph we are trying to find a layout for.

function ForcePullToGrid:preprocess(v)
  self.p = v
end


-- Applying the force to the vertices and adding the effect to the passed net
-- force array
--
-- @param data The parameters needed to apply the force: The options table,
--              the current time stamp, an array containing the summed up net
--              forces

function ForcePullToGrid:applyTo(data)
  -- locals for speed
  local cap = self.force.cap
  local net_forces = data.net_forces
  local t_max = self.options["maximum time"]
  local grid_x_distance = self.options["grid x length"]
  local grid_y_distance = self.options["grid y length"]
  local t_now = data.t_now
  local p = self.p
  local time_fun = self.force.time_fun
  local length = 5--self.options["node distance"]

  -- Evaluate time function
  local time_factor = time_fun(t_max, t_now)
  if time_factor == 0 then
    return
  end

  for _, v in ipairs(p) do
    -- dereference
    local p1 = v.pos
    local p2_x = round(p1.x/grid_x_distance)*grid_x_distance
    local p2_y = round(p1.y/grid_y_distance)*grid_y_distance

    -- calculate distance between vertex and grid point
    local x = p1.x - p2_x
    local y = p1.y - p2_y
    local d = max(sqrt(x*x+y*y),0.1)
    local l = -d/(length*length)

    -- Include time function
    local h = l * time_factor

    -- scale effect according to direction
    local f = x * h
    local g = y * h

    -- cap effect if necessary
    if cap then
      if f <= 0 then
        x = max(-cap, f)
      else
        x = min(cap, f)
      end

      if g <= 0 then
        y = max(-cap, g)
      else
        y = min(cap, g)
      end
    else
      x = f
      y = g
    end

    -- add calculated effect to net forces
    local c1 = net_forces[v]
    c1.x = c1.x - x
    c1.y = c1.y - y
  end
end

return ForcePullToGrid