-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local CycleRemovalBergerS1990b = {}

local lib = require("pgf.gd.lib")


function CycleRemovalBergerS1990b:run()
  -- remember edges that were removed
  local removed = {}

  -- remember edges that need to be reversed
  local reverse = {}

  -- iterate over all nodes of the graph
  for _,j in ipairs(lib.random_permutation(#self.graph.nodes)) do
    local node = self.graph.nodes[j]
    -- get all outgoing edges that have not been removed yet
    -- get all outgoing edges that have not been removed yet
    local out_edges = lib.imap(node:getOutgoingEdges(),
      function (edge)
        if not removed[edge] then return edge end
      end)

    -- get all incoming edges that have not been removed yet
    local in_edges = lib.imap(node:getIncomingEdges(),
      function (edge)
        if not removed[edge] then return edge end
      end)

    if #out_edges >= #in_edges then
      -- we have more outgoing than incoming edges, reverse all incoming
      -- edges and mark all incident edges as removed

      for _,edge in ipairs(out_edges) do
        removed[edge] = true
      end
      for _,edge in ipairs(in_edges) do
        reverse[edge] = true
        removed[edge] = true
      end
    else
      -- we have more incoming than outgoing edges, reverse all outgoing
      -- edges and mark all incident edges as removed

      for _,edge in ipairs(out_edges) do
        reverse[edge] = true
        removed[edge] = true
      end
      for _,edge in ipairs(in_edges) do
        removed[edge] = true
      end
    end
  end

  -- mark edges as reversed
  for edge in pairs(reverse) do
    edge.reversed = true
  end
end



-- done

return CycleRemovalBergerS1990b
