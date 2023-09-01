-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Imports
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare

local routing = require("pgf.gd.routing")

-- The algorithm class
local Tantau2012 = {}

---
declare {
  key       = "simple necklace layout",
  algorithm = Tantau2012,

  postconditions = {
    upward_oriented = true
  },

  documentation_in = "pgf.gd.circular.doc"
}



-- Imports

local Coordinate = require "pgf.gd.model.Coordinate"
local Hints      = require "pgf.gd.routing.Hints"

local lib        = require "pgf.gd.lib"




-- The implementation

function Tantau2012:run()
  local g = self.ugraph
  local vertices = g.vertices
  local n = #vertices

  local sib_dists = self:computeNodeDistances ()
  local radii = self:computeNodeRadii()
  local diam, adjusted_radii = self:adjustNodeRadii(sib_dists, radii)

  -- Compute total necessary length. For this, iterate over all
  -- consecutive pairs and keep track of the necessary space for
  -- this node. We imagine the nodes to be aligned from left to
  -- right in a line.
  local carry = 0
  local positions = {}
  local function wrap(i) return (i-1)%n + 1 end
  local ideal_pos = 0
  for i = 1,n do
    positions[i] = ideal_pos + carry
    ideal_pos = ideal_pos + sib_dists[i]
    local node_sep =
      lib.lookup_option('node post sep', vertices[i], g) +
      lib.lookup_option('node pre sep', vertices[wrap(i+1)], g)
    local arc = node_sep + adjusted_radii[i] + adjusted_radii[wrap(i+1)]
    local needed = carry + arc
    local dist = math.sin( arc/diam ) * diam
    needed = needed + math.max ((radii[i] + radii[wrap(i+1)]+node_sep)-dist, 0)
    carry = math.max(needed-sib_dists[i],0)
  end
  local length = ideal_pos + carry

  local radius = length / (2 * math.pi)
  for i,vertex in ipairs(vertices) do
    vertex.pos.x = radius * math.cos(2 * math.pi * (positions[i] / length + 1/4))
    vertex.pos.y = -radius * math.sin(2 * math.pi * (positions[i] / length + 1/4))
  end

  -- Add routing infos
  local necklace = lib.icopy({g.vertices[1]}, lib.icopy(g.vertices))
  Hints.addNecklaceCircleHint(g, necklace, nil, true)
end


function Tantau2012:computeNodeDistances()
  local sib_dists = {}
  local sum_length = 0
  local vertices = self.digraph.vertices
  for i=1,#vertices do
    sib_dists[i] = lib.lookup_option('node distance', vertices[i], self.digraph)
    sum_length = sum_length + sib_dists[i]
  end

  local missing_length = self.digraph.options['radius'] * 2 * math.pi - sum_length
  if missing_length > 0 then
    -- Ok, the sib_dists to not add up to the desired minimum value.
    -- What should we do? Hmm... We increase all by the missing amount:
    for i=1,#vertices do
      sib_dists[i] = sib_dists[i] + missing_length/#vertices
    end
  end

  sib_dists.total = math.max(self.digraph.options['radius'] * 2 * math.pi, sum_length)

  return sib_dists
end


function Tantau2012:computeNodeRadii()
  local radii = {}
  for i,v in ipairs(self.digraph.vertices) do
    local min_x, min_y, max_x, max_y = v:boundingBox()
    local w, h = max_x-min_x, max_y-min_y
    if v.shape == "circle" or v.shape == "ellipse" then
      radii[i] = math.max(w,h)/2
    else
      radii[i] = math.sqrt(w*w + h*h)/2
    end
  end
  return radii
end


function Tantau2012:adjustNodeRadii(sib_dists,radii)
  local total = 0
  local max_rad = 0
  for i=1,#radii do
    total = total + 2*radii[i]
            + lib.lookup_option('node post sep', self.digraph.vertices[i], self.digraph)
            + lib.lookup_option('node pre sep', self.digraph.vertices[i], self.digraph)
    max_rad = math.max(max_rad, radii[i])
  end
  total = math.max(total, sib_dists.total, max_rad*math.pi)
  local diam = total/(math.pi)

  -- Now, adjust the radii:
  local adjusted_radii = {}
  for i=1,#radii do
    adjusted_radii[i] = (math.pi - 2*math.acos(radii[i]/diam))*diam/2
  end

  return diam, adjusted_radii
end


-- done

return Tantau2012
