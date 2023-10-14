-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--- This is a subclass of ForceTemplate, which is used to implement forces
-- that work on individual vertices. The forces depend on the canvas position
-- of the vertices. This class is e.~g.~ used for gravitational forces.

local ForceTemplate = require "pgf.gd.force.jedi.base.ForceTemplate"
local lib = require "pgf.gd.lib"

local ForceCanvasPosition = lib.class { base_class = ForceTemplate }

-- Localize math functions
local max = math.max
local sqrt = math.sqrt
local min = math.min

-- Implementation starts here:

function ForceCanvasPosition:constructor ()
  ForceTemplate.constructor(self)
  self.p = {}
end


-- This force class works on individual vertices and only depends on their
-- current position. Thus the vertex table of the current graph is simply
-- copied to the variable |p|.
--
--  @param v The vertices of the graph we are trying to find a layout for.

function ForceCanvasPosition:preprocess(v)
  self.p = v
end


-- Applying the force to the vertices and adding the effect to the passed net
-- force array
--
-- @param data The parameters needed to apply the force: The options table,
--             the current time stamp, an array containing the summed up net
--             forces

function ForceCanvasPosition:applyTo(data)
  --localize
  local cap = self.force.cap
  local fun_u = self.force.fun_u
  local net_forces = data.net_forces
  local t_max = self.options["maximum time"]
  local t_now = data.t_now
  local p = self.p
  local time_fun = self.force.time_fun
  local initial_gravity = self.options["gravity"]
  local fw_attributes = self.fw_attributes

  -- evaluate time function
  local time_factor = time_fun(t_max, t_now)
  if time_factor == 0 then
    return
  end

  -- Find midpoint of all vertices since they will be attracted to this point
  local centroid_x, centroid_y = 0,0
  for _, v in ipairs(p) do
    local pos = v.pos
    centroid_x = centroid_x + pos.x
    centroid_y = centroid_y + pos.y
  end
  centroid_x = centroid_x/#p
  centroid_y = centroid_y/#p

  -- Iterate over the precomputed vertex list
  for _, v in ipairs(p) do
    -- localize
    local p1 = v.pos

    -- apply force function
    local factor = fun_u{attributes = fw_attributes, u = v}

    -- calculate distance between vertex and centroid
    local x = centroid_x - p1.x
    local y = centroid_y - p1.y

    -- calculate effect on x/y
    local h = factor * time_factor
    x = x * h
    y = y * h

    -- cap effect if necessary
    if cap then
      if x <= 0 then
        x = max(-cap, x)
      else
        x = min(cap, x)
      end
      if y <= 0 then
        y = max(-cap, y)
      else
        y = min(cap, y)
      end
    end

    -- add calculated effect to net forces
    local c = net_forces[v]
    c.x = c.x + x
    c.y = c.y + y
  end
end

return ForceCanvasPosition