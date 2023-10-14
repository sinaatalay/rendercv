-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--- This is the parent class for initial layout algorithms. It provides a
-- constructor and methods stubs to be overwritten in the subclasses as well
-- as placing vertices which are |desired at| a certain point.

-- Imports
local lib = require "pgf.gd.lib"

local InitialTemplate = lib.class {}

-- constructor
function InitialTemplate:constructor()
  self.vertices = self.vertices
  self.options = self.options
  self.desired_vertices = self.desired_vertices
end

-- Method placing |desired at| vertices at the point they are desired
--
-- @params desired_vertices A table containing all the vertices where the
-- |desired at| option is set.
--
-- @return |placed| A boolean array stating if vertices have been placed yet
-- @return |centroid_x| The x-coordinate of the midpoint of all placed vertices
-- @return |centroid_y| The y-coordinate of the midpoint of all placed vertices

function InitialTemplate:desired(desired_vertices)
  local placed = {}

  local centroid_x, centroid_y = 0, 0

  local size = 0
  for v, da in pairs(desired_vertices) do
    local p = v.pos
    local x, y = da.x, da.y
    p.x = x or 0
    p.y = y or 0
    centroid_x = centroid_x + x
    centroid_y = centroid_y + y
    placed[v] = true
    size = size +1
  end
  if size>0 then
    centroid_x = centroid_x / size
    centroid_y = centroid_y / size
  end

  return placed, centroid_x, centroid_y
end

-- Method stub for running the layout algorithm
function InitialTemplate:run()
end

return InitialTemplate