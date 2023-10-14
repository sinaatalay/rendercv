-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- This is a subclass of ForceTemplate, which is used to implement forces
-- that work on individual vertices. Forces of this kind simply add an
-- absolute value set in the force data to each vertex' $x$ and $y$ coordinate

-- Imports
local ForceTemplate = require "pgf.gd.force.jedi.base.ForceTemplate"
local lib = require "pgf.gd.lib"
local Preprocessing = require "pgf.gd.force.jedi.base.Preprocessing"

-- Localize math functions
local max = math.max
local sqrt = math.sqrt
local min = math.min

-- Implementation starts here:

local ForceAbsoluteValue = lib.class { base_class = ForceTemplate }

function ForceAbsoluteValue:constructor ()
  ForceTemplate.constructor(self)
  self.p = {}
end


-- This force class works on a vertex array that is part of the force data
-- defined when adding the force. This array is copied into p. All vertices of
-- the graph are saved in the local variable |ver|.
--
-- @param v The vertices of the graph we are trying to find a layout for.

function ForceAbsoluteValue:preprocess(v)
  self.ver = v
  self.p = self.force.vertices
end


-- Applying the force to the vertices and adding the effect to the passed net
-- force array
--
-- @param data The parameters needed to apply the force: The options table,
--             the current time stamp, an array containing the summed up net
--             forces

function ForceAbsoluteValue:applyTo(data)
  -- locals for speed
  local cap = self.force.cap
  local value  = self.force.value
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

  for _,v in ipairs(self.ver) do
    for _, i in ipairs (self.p) do
      -- Is the vertex in the list?
      if v.name == i then

        local f = value * time_factor

        -- cap effect if necessary
        if cap then
          if f <= 0 then
            x = max(-cap, f)
          else
            x = min(cap, f)
          end
        end

        -- add calculated effect to net forces
        local c1 = net_forces[v]
        c1.x = c1.x + f
        c1.y = c1.y + f
      end
    end
  end
end

return ForceAbsoluteValue