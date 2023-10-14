-- Copyright 2015 by Malte Skambath
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


local GreedyTemporalCycleRemoval = {}

-- Imports
local lib        = require "pgf.gd.lib"
local declare    = require("pgf.gd.interface.InterfaceToAlgorithms").declare

local Vertex     = require "pgf.gd.model.Vertex"
local Digraph    = require "pgf.gd.model.Digraph"
local Coordinate = require "pgf.gd.model.Coordinate"

local PriorityQueue           = require "pgf.gd.lib.PriorityQueue"

-- Keys

---

declare {
  key     = "split critical arc head",
  type    = "boolean",
  initial = true,
  summary = "Specifies, that for a critical the tail node is separated"
}

---

declare {
  key     = "split critical arc tail",
  type    = "boolean",
  initial = true,
  summary = "Specifies, that for a critical the tail node is separated"
}

---

declare {
  key       = "greedy temporal cycle removal",
  algorithm = GreedyTemporalCycleRemoval,
  phase     = "temporal cycle removal",
  phase_default = true,
  summary = [["
    A temporal dependency cycle is a cyclic path in the supergraph of
    an evolving graph. Use this key if you want remove all temporal
    dependency cycles by a greedy strategy which incrementally inserts
    edge checks if this edge creates a cycle and splits at least one node
    into two supernode at a given time.
  "]],
  documentation = [["
    See ToDo
  "]]
}

-- Help functions
local function reachable(graph, v, w)
  local visited = {}
  local queue = PriorityQueue.new()
  queue:enqueue(v,1)
  while not queue:isEmpty() do
    local vertex = queue:dequeue()
    if vertex==w then
      return true
    end
    local outgoings = graph:outgoing(vertex)
    for _, e in ipairs(outgoings) do
      local head = e.head
      if not visited[head] then
        visited[head] = true
        if head == w then
          return true
        else
          queue:enqueue(head,1)
        end
      end
    end
  end
  return false
end

-- Implementation

function GreedyTemporalCycleRemoval:run()
  local supergraph = assert(self.supergraph, "no supergraph passed")
  local digraph    = assert(self.digraph,    "no digraph passed to the phase")
  local split_tail = digraph.options["split critical arc tail"]
  local split_head = digraph.options["split critical arc head"]
  assert(split_tail or split_head, "without splitting nodes dependency cycles cannot be removed.")

  self:iterativeCycleRemoval(supergraph, split_tail, split_head)
end

--
-- Resolves all dependencies by splitting supernodes into multiple supernodes.
-- To resolve a cycle each edge will be inserted into a dependency graph
-- successively. Each time such edge closes a cycle the head and tail will
-- be split at the related snapshot.
--
-- @param supergraph
--
function GreedyTemporalCycleRemoval:iterativeCycleRemoval(supergraph, split_tail, split_head)
  -- Build up the global dependency graph
  -- A supernode v directly depends on another supernode w if
  -- there is a snapshot in which w is a child of w
  local dependency_graph = Digraph.new(supergraph)
  local stable_arcs = {}
  for i, snapshot in ipairs(supergraph.snapshots) do
    --local tree = snapshot.spanning_tree
  for _,tree in ipairs(snapshot.spanning_trees) do
    local new_arcs      = {}

    for _, e in ipairs(tree.arcs) do
      if e.head.kind ~= "dummy" and e.tail.kind~="dummy" then
        table.insert(new_arcs, e)

        local sv = supergraph:getSupervertex(e.tail)
        local sw = supergraph:getSupervertex(e.head)
        local dep_arc = dependency_graph:arc(sv, sw)


        if (not dep_arc)   then
          -- check if the edge v->w closes a cycle in the dependency graph
          --pgf.debug{dependency_graph}
          local cycle_arc = reachable(dependency_graph, sw, sv)
          dep_arc = dependency_graph:connect(sv,sw)
--          texio.write("\ncheck ".. sv.name.."->" .. sw.name)
          if cycle_arc then
            if split_tail then
              supergraph:splitSupervertex(sv, { [1]=snapshot })
            end
            if split_head then
              supergraph:splitSupervertex(sw, { [1]=snapshot })
            end

            -- rebuild dependency graph
            dependency_graph = Digraph.new(supergraph)

            for _, arc in ipairs(stable_arcs) do
              dependency_graph:connect(arc.tail, arc.head)
            end

            for _, arc in ipairs(new_arcs) do
              local sv = supergraph:getSupervertex(arc.tail)
              local sw = supergraph:getSupervertex(arc.head)
              dependency_graph:connect(sv, sw)
            end
          end -- end of resolve cycle_arc
        end
      end
    end
    -- Stable Arcs:
    for _, arc in ipairs(new_arcs) do

      local sv = supergraph:getSupervertex(arc.tail)
      local sw = supergraph:getSupervertex(arc.head)
      local deparc = dependency_graph:arc(sv, sw)
--      if not deparc or not stable_arcs[deparc] then
--        stable_arcs[deparc] = true
        table.insert(stable_arcs, deparc)
--      end

    end
  end -- end for spanning_tree
  end -- end for snapshot
end


-- Done

return GreedyTemporalCycleRemoval
