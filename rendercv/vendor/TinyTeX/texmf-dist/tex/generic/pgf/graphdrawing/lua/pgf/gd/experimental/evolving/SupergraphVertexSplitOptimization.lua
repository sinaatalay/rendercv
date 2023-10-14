-- Copyright 2015 by Malte Skambath
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


local SupergraphVertexSplitOptimization = {}

-- Imports
local lib        = require "pgf.gd.lib"
local declare    = require("pgf.gd.interface.InterfaceToAlgorithms").declare

local Vertex     = require "pgf.gd.model.Vertex"
local Digraph    = require "pgf.gd.model.Digraph"
local Coordinate = require "pgf.gd.model.Coordinate"

declare {
  key     = "split me",
  type    = "boolean",
  initial = false
}

declare {
  key     = "split on disappearing",
  type    = "boolean",
  initial = true
}

declare {
  key     = "split on disjoint neighbors",
  type    = "boolean",
  initial = false
}

declare {
  key     = "split on disjoint children",
  type    = "boolean",
  initial = false
}

declare {
  key     = "split on disjoint parents",
  type    = "boolean",
  initial = false
}

declare {
  key     = "split all supervertices",
  type    = "boolean",
  initial = false
}

declare {
  key       = "unbound vertex splitting",
  algorithm = SupergraphVertexSplitOptimization,
  phase     = "supergraph optimization",
  phase_default = true,
  summary = [["
    Use this key if you want to disable animations.
    Instead of producing animations the evolving graph animation phasephase animates all vertices including movements and
    fade in or fade out animations.
  "]],
  documentation = [["
    See ToDo
  "]]
}



-- Help functions


-- Implementation

function SupergraphVertexSplitOptimization:run()
  local supergraph = assert(self.supergraph, "no supergraph passed")

  local split_on_dissapearing       = self.digraph.options["split on disappearing"]
  local split_on_no_common_neighbor = self.digraph.options["split on disjoint neighbors"]
  local split_on_no_common_child    = self.digraph.options["split on disjoint children"]
  local split_on_no_common_parent   = self.digraph.options["split on disjoint parents"]
  local split_all                   = self.digraph.options["split all supervertices"]

  for _, supernode in ipairs(supergraph.vertices) do
    -- follow trace of the supernode
    local snapshots      = supergraph:getSnapshots(supernode)
    local splitsnapshots = {}

    for i=2, #snapshots do
      local s = snapshots[i]
      local s_prev = snapshots[i - 1]
      local can_split = false

      if supergraph:consecutiveSnapshots(s_prev, s) then
        local v1 = supergraph:getSnapshotVertex(supernode, s_prev)
        local v2 = supergraph:getSnapshotVertex(supernode, s)
        local is_child1 = {}
        local is_parent1   = {}
        local is_neighbor1  = {}

        local incoming1 = s_prev:incoming(v1)
        local outgoing1 = s_prev:outgoing(v1)

        for _,e in ipairs(incoming1) do
          local p = supergraph:getSupervertex(e.tail)
          if p then
            is_parent1[p]   = true
            is_neighbor1[p] = true
          end
        end

        for _,e in ipairs(outgoing1) do
          local p = supergraph:getSupervertex(e.head)
          if p then
            is_child1[p] = true
            is_neighbor1[p] = true
          end
        end

        local incoming2 = s:incoming(v2)
        local outgoing2 = s:outgoing(v2)

        no_common_parent   = true
        no_common_child    = true
        no_common_neighbor = true
        for _,e in ipairs(incoming2) do
          local p = supergraph:getSupervertex(e.tail)
          if p then
            if is_neighbor1[p] then
              no_common_neighbor = false
            end
            if is_parent1[p] then
              no_common_parent = false
            end
            if (not no_common_neighbor) and (not no_common_parent) then
              break
            end
          end
        end

        for _,e in ipairs(outgoing2) do
          local p = supergraph:getSupervertex(e.head)
          if p then
            if is_neighbor1[p] then
              no_common_neighbor = false
            end
            if is_child1[p] then
              no_common_child = false
            end
             if (not no_common_neighbor) and (not no_common_child) then
              break
            end
          end
        end



        if no_common_neighbor and split_on_no_common_neighbor then
          can_split = true
          --texio.write("[N@".. s.timestamp .."]")
        end
        if no_common_parent and split_on_no_common_parent then
          can_split = true
          --texio.write("[P@".. s.timestamp .."]")
        end
        if no_common_child and split_on_no_common_child then
          can_split = true
          --texio.write("[N@".. s.timestamp .."]")
        end
        if v2.options["split me"] then
          can_split = true
        end
          else
        can_split = true
        --texio.write("[R@".. s.timestamp .."]")
          end
          if can_split or split_all  then
        table.insert(splitsnapshots, s)
      end
    end
    if #splitsnapshots>0 then
      supergraph:splitSupervertex(supernode, splitsnapshots)
    end
  end
end




-- Done

return SupergraphVertexSplitOptimization
