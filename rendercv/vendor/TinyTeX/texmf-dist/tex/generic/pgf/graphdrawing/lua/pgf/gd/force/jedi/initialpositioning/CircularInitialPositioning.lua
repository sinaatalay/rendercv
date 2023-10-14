-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- This class implements an initial position algorithm for graph drawing, placing the vertices on
-- a circle with th radius given by the |radius| key
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local InitialTemplate = require "pgf.gd.force.jedi.base.InitialTemplate"
local lib = require "pgf.gd.lib"

local CircularInitialPositioning =  lib.class { base_class = InitialTemplate }


---
declare {
  key = "circular initial position",
  algorithm = CircularInitialPositioning,
  phase = "initial positioning force framework",
  phase_default = true
}

-- Implementation starts here:

function CircularInitialPositioning:constructor ()
  InitialTemplate.constructor(self)
end

function CircularInitialPositioning:run()
  -- locals for speed
  local vertices = self.vertices
  local tmp =  (self.options["node pre sep"] + self.options["node post sep"]) +
    (self.options["sibling pre sep"] + self.options["sibling post sep"])
  local min_radius = tmp * #self.vertices/2/math.pi
  local radius = math.max(self.options.radius, min_radius)
  local desired_vertices = self.desired_vertices
  -- place vertices where the |desired at | option has been set first
  local placed, centroid_x, centroid_y = InitialTemplate:desired(desired_vertices)
  local angle = 2*math.pi / #vertices
  local a = angle
  local sin = math.sin
  local cos = math.cos

  for _, vertex in ipairs(vertices) do
    -- place all other vertices with respect to the one already placed
    if placed[vertex] == nil then
      local p = vertex.pos
      p.x = sin(a) * radius + centroid_x
      p.y = cos(a) * radius + centroid_y
      a = a + angle
    end
  end
end


return CircularInitialPositioning