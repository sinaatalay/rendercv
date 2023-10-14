-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- This is a subclass of ForceTemplate, which is used to implement forces
-- that work on individual vertices and pulls them to a specific point on the
-- canvas. This point is given by the |desired at| option. The forces depend
-- on the canvas position of the vertices relative to the canvas point it is
-- pulled to.


-- Imports
local ForceTemplate = require "pgf.gd.force.jedi.base.ForceTemplate"
local lib = require "pgf.gd.lib"
local Preprocessing = require "pgf.gd.force.jedi.base.Preprocessing"

-- Localize math functions
local max = math.max
local sqrt = math.sqrt
local min = math.min

-- Implementation starts here:

local ForcePullToPoint = lib.class { base_class = ForceTemplate }

function ForcePullToPoint:constructor ()
  ForceTemplate.constructor(self)
  self.p = {}
end

-- This force class works on individual vertices and depends on their
-- current position as well as the point it is desired at. Thus all vertices
-- where the |desired at| option is set are added to the table |p| together
-- with the point where they are wanted.
--
--  @param v The vertices of the graph we are trying to find a layout for.

function ForcePullToPoint:preprocess(v)
  for _,vertex in ipairs(v) do
    if vertex.options then
      local da = vertex.options["desired at"]
        if da then
          self.p[vertex]= {da}
      end
    end
  end
end


-- Applying the force to the vertices and adding the effect to the passed net
-- force array
--
-- @param data The parameters needed to apply the force: The options table,
--             the current time stamp, an array containing the summed up net
--             forces

function ForcePullToPoint:applyTo(data)
  -- locals for speed
  local cap = self.force.cap
  local net_forces = data.net_forces
  local t_max = self.options["maximum time"]
  local t_now = data.t_now
  local p = self.p
  local time_fun = self.force.time_fun

  -- Evaluate time function
  local time_factor = time_fun(t_max, t_now)
  if time_factor == 0 then
    return
  end

  for v, point in pairs(p) do
    -- dereference
    local p1 = v.pos
    local p2 = point[1]

    -- calculate distance between vertex and centroid
    local x = p1.x - p2.x
    local y = p1.y - p2.y
    local d = max(sqrt(x*x+y*y),0.1)

    -- Include time function
    local h = d * time_factor

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

return ForcePullToPoint