-- Copyright 2011 by Jannis Pohlmann
-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



--- The Iterators class is a singleton object.
--
-- It provides advanced iterators.

local Iterators = {}

-- Namespace

local lib = require("pgf.gd.lib")



--- Iterator for traversing a \meta{dag} using a topological sorting.
--
-- A topological sorting of a directed graph is a linear ordering of its
-- nodes such that, for every edge |(u,v)|, |u| comes before |v|.
--
-- Important note: if performed on a graph with at least one cycle a
-- topological sorting is impossible. Thus, the nodes returned from the
-- iterator are not guaranteed to satisfy the ``|u| comes before |v|''
-- criterion. The iterator may even terminate early or loop forever.
--
-- @param graph A directed acyclic graph.
--
-- @return An iterator for traversing \meta{graph} in a topological order.
--
function Iterators.topologicallySorted(dag)
  -- track visited edges
  local deleted_edges = {}

  -- collect all sources (nodes with no incoming edges) of the dag
  local sources = lib.imap(dag.nodes, function (node) if node:getInDegree() == 0 then return node end end)

  -- return the iterator function
  return function ()
    while #sources > 0 do
      -- fetch the next sink from the queue
      local source = table.remove(sources, 1)

      -- get its outgoing edges
      local out_edges = source:getOutgoingEdges()

      -- iterate over all outgoing edges we haven't visited yet
      for _,edge in ipairs(out_edges) do
        if not deleted_edges[edge] then
          -- mark the edge as visited
          deleted_edges[edge] = true

          -- get the node at the other end of the edge
          local neighbour = edge:getNeighbour(source)

          -- get a list of all incoming edges of the neighbor that have
          -- not been visited yet
          local in_edges = lib.imap(neighbour:getIncomingEdges(),
                        function (edge) if not deleted_edges[edge] then return edge end end)

          -- if there are no such edges then we have a new source
          if #in_edges == 0 then
            sources[#sources+1] = neighbour
          end
        end
      end

      -- return the current source
      return source
    end

    -- the iterator terminates if there are no sources left
    return nil
  end
end



-- Done

return Iterators
