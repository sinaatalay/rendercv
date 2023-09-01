-- Copyright 2014 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- The class; it processes necklace hints.

local NecklaceRouting = {}


-- Namespace
require("pgf.gd.routing").NecklaceRouting = NecklaceRouting

-- Imports
local declare    = require("pgf.gd.interface.InterfaceToAlgorithms").declare

local Hints      = require "pgf.gd.routing.Hints"
local Path       = require "pgf.gd.model.Path"


---
declare {
  key       = "necklace routing",
  algorithm = NecklaceRouting,

  phase     = "edge routing",

  summary   = "Bends all edges of a graph that lie on ``necklaces'' along these necklaces.",

  documentation = [["
    Some graph drawing algorithms lay out some or all nodes along a
    path, which is then called a \emph{necklace}. For instance, the
    |simple necklace layout| places all nodes on a circle and that
    circle is the ``necklace''. When the |necklace routing| edge
    routing algorithm is selected, all edges that connect subsequent
    nodes on such a necklace are bend in such a way that the
    ``follow the necklace path''. In the example case, this will
    cause all edges that connect adjacent nodes to become arcs on
    of the circle on which the nodes lie.

    Note that local edge routing options for an edge may overrule
    the edge routing computed by the algorithm as in the edge from 6
    to 7 in the example.
  "]],

  examples = [["
    \tikz \graph [simple necklace layout, node distance=1.5cm,
                  necklace routing,
                  nodes={draw,circle}, edges={>={Stealth[round,sep,bend]}}]
      { 1 -> 2 [minimum size=30pt] <- 3 <-> 4 --
        5 -- 6 -- [bend left] 7 -- 1 -- 4 };
    "]]
}



-- The implementation

function NecklaceRouting:run()
  local ugraph = self.ugraph

  for _,entry in ipairs(Hints.getNecklaceHints(ugraph)) do
    assert (entry.center) -- no other necklace types, yet
    local prev
    for _,vertex in ipairs(entry.necklace) do
      if prev then
        local a = ugraph:arc(prev, vertex)
        if a then
          local p = Path.new()
          p:appendMoveto(a.tail.pos:clone())
          p:appendArcTo(a.head.pos:clone(), entry.center, entry.clockwise)
          a.path = p
        end
      end
      prev = vertex
    end
  end
end


-- done

return NecklaceRouting
