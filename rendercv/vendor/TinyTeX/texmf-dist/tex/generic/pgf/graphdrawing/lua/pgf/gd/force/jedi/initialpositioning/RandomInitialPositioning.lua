-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- This class implements an initial position algorithm for graph drawing,
-- placing the vertices at random positions.
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local InitialTemplate = require "pgf.gd.force.jedi.base.InitialTemplate"
local lib = require "pgf.gd.lib"

local RandomInitialPositioning = lib.class { base_class = InitialTemplate }

---
declare {
  key = "random initial position",
  algorithm = RandomInitialPositioning,
  phase = "initial positioning force framework"
}

-- Implementation starts here:

function RandomInitialPositioning:constructor ()
  InitialTemplate.constructor(self)
end

function RandomInitialPositioning:run()
  -- locals for speed
  local random = lib.random
  local vertices = self.vertices
  local desired_vertices = self.desired_vertices
  -- place vertices where the |desired at | option has been set first
  local placed, centroid_x, centroid_y = InitialTemplate:desired(desired_vertices)

  for _, vertex in ipairs(vertices) do
    -- place all other vertices with respect to the one already placed
    if placed[vertex] == nil then
      p = vertex.pos
      p.x = 100 * random() + centroid_x
      p.y = 100 * random() + centroid_y
    end
  end
end

return RandomInitialPositioning
