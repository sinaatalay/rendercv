-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- This class implements an initial position algorithm for graph drawing,
-- placing the vertices on a grid with square cells with width |node distance|
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local InitialTemplate = require "pgf.gd.force.jedi.base.InitialTemplate"
local lib = require "pgf.gd.lib"

local GridInitialPositioning =  lib.class { base_class = InitialTemplate }


---
declare {
  key = "grid initial position",
  algorithm = GridInitialPositioning,
  phase = "initial positioning force framework",
}

-- Implementation starts here:

function GridInitialPositioning:constructor ()
  InitialTemplate.constructor(self)
end

function GridInitialPositioning:run()
  -- locals for speed
  local vertices = self.vertices
  local dist = self.options["node distance"]
  local desired_vertices = self.desired_vertices
  -- place vertices where the |desired at | option has been set first
  local placed, centroid_x, centroid_y = InitialTemplate:desired(desired_vertices)
  local n = math.ceil(math.sqrt(#vertices))
  local x = -dist
  local y = 0

  for i, vertex in ipairs(vertices) do
    -- place all other vertices with respect to the one already placed
    if placed[vertex] == nil then
      if i <= (y/dist+1)*n then
        x = x + dist
      else
        x = 0
        y = y + dist
      end
      local p = vertex.pos
      p.x = x + centroid_x
      p.y = y + centroid_y
    end
  end
end


return GridInitialPositioning