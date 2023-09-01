-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--- This is a subclass of ForceTemplate, which is used to implement forces between
-- vertex pairs. The forces depend on the graph distance of the vertices in
-- the pair. This class is e.\,g.\ used for spring forces.


local ForceTemplate = require "pgf.gd.force.jedi.base.ForceTemplate"
local lib = require "pgf.gd.lib"
local Preprocessing = require "pgf.gd.force.jedi.base.Preprocessing"

-- Localize math functions
local max = math.max
local sqrt = math.sqrt
local min = math.min

-- Implementation starts here:

local ForceGraphDistance = lib.class { base_class = ForceTemplate }

function ForceGraphDistance:constructor ()
  ForceTemplate.constructor(self)
  self.p = {}
end


-- This force class works on all pairwise disjoint vertex pairs connected by
-- a path of length maximum $n$. The parameter $n$ is given by the engineer in
-- the force declaration. This function generates a new graph object
-- containing all vertices from the original graph and arcs between all
-- pairwise disjoint vertex pairs. The arcs-table of this new object will be
-- saved in the variable |p|.
--
--  @param v The vertices of the graph we are trying to find a layout for.

function ForceGraphDistance:preprocess(v, a)
  self.p = Preprocessing.overExactlyNPairs(v, a, self.force.n)
end


-- Applying the force to the vertices and adding the effect to the passed net
-- force array
--
-- @param data The parameters needed to apply the force: The options table,
--             the current time stamp, an array containing the summed up net
--             forces

function ForceGraphDistance:applyTo(data)
  -- locals for speed
  local cap = self.force.cap
  local fun_u = self.force.fun_u
  local fun_v = self.force.fun_v
  local net_forces = data.net_forces
  local t_max = self.options["maximum time"]
  local t_now = data.t_now
  local k = data.k
  local p = self.p
  local time_fun = self.force.time_fun
  local fw_attributes = self.fw_attributes

  -- Evaluate time function
  local time_factor = time_fun(t_max, t_now)
  if time_factor == 0 then
    return
  end

  if not fun_v then
    local data = { k = k, attributes = fw_attributes }
    for _, i in ipairs(p) do
      -- dereference
      local p2 = i.head
      local p1 = i.tail
      local p2_pos = p2.pos
      local p1_pos = p1.pos

      -- calculate distance between two points
      local x = p2_pos.x - p1_pos.x
      local y = p2_pos.y - p1_pos.y
      local d = max(sqrt(x*x+y*y),0.1)

      -- apply force function to distance and k (natural spring length)
      data.u = p2
      data.v = p1
      data.d = d
      local e = fun_u(data)

      -- Include time function
      local f = e * time_factor / d

      -- calculate effect on x/y
      local g = x * f
      local h = y * f

      -- cap effect if necessary
      if cap then
        if g <= 0 then
          x = max(-cap, g)
        else
          x = min(cap, g)
        end

        if g <= 0 then
          y = max(-cap, h)
        else
          y = min(cap, h)
        end
      else
        x = g
        y = h
      end

      -- add calculated effect to net forces
      local c1 = net_forces[p1]
      c1.x = c1.x - x
      c1.y = c1.y - y
      local c2 = net_forces[p2]
      c2.x = c2.x + x
      c2.y = c2.y + y
    end
  else
    -- There are different functions for head and tail vertex
    local data = { k = k, attributes = fw_attributes }
    for _, i in ipairs(p) do
      -- dereference
      local p2 = i.head
      local p1 = i.tail
      local p2_pos = p2.pos
      local p1_pos = p1.pos

      -- calculate distance between two points
      local x = p2_pos.x - p1_pos.x
      local y = p2_pos.y - p1_pos.y

      local d = max(sqrt(x*x+y*y),0.1)

      -- apply force function to distance and k (natural spring length
      data.u = p2
      data.v = p1
      data.d = d
      local e_head = fun_u(data)
      local e_tail = fun_v(data)

      -- Include time function
      local f_head = time_factor * e_head / d
      local f_tail = time_factor * e_tail / d

      -- calculate effect on x/y
      local g_head = x * f_head
      local g_tail = x * f_tail
      local h_head = y * f_head
      local h_tail = y * f_tail

      -- cap effect if necessary
      local x_head, x_tail, y_head, y_tail
      if cap then
        if g_head <= 0 then
          x_head = max(-cap, g_head)
        else
          x_head = min(cap, g_head)
        end

        if g_tail <= 0 then
          x_tail = max(-cap, g_tail)
        else
          x_tail = min(cap, g_tail)
        end

        if h_head <= 0 then
          y_head = max(-cap, h_head)
        else
          y_head = min(cap, h_head)
        end

        if h_tail <= 0 then
          y_tail = max(-cap, h_tail)
        else
          y_tail = min(cap, h_tail)
        end
      else
        x_head = g_head
        x_tail = g_tail
        y_head = h_head
        y_tail = h_tail
      end

      -- add calculated effect to net forces
      local c1 = net_forces[p1]
      c1.x = c1.x - x_tail
      c1.y = c1.y - y_tail
      local c2 = net_forces[p2]
      c2.x = c2.x + x_head
      c2.y = c2.y + y_head
    end
  end
end

return ForceGraphDistance