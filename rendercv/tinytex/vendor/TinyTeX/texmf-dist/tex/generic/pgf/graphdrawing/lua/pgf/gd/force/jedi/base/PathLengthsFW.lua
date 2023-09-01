-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- This is a helper class providing different functions that deal with graph
-- distances. This class can be used by engineers and implementers if they
-- need to calculate anything regarding graph distances.

local PathLengths = {}

-- Imports
local PriorityQueue = require "pgf.gd.lib.PriorityQueue"
local Preprocessing = require "pgf.gd.force.jedi.base.Preprocessing"

-- This algorithm conducts a breadth first search on the graph it is given.
--
-- @param ugraph The graph on which the search should be conducted
--
-- @return A table holding every vertex $v$ as key and a table as value. The
--         value table holds all other vertices $u$ as keys and their shortest
--         distance to $v$ as value

function PathLengths:breadthFirstSearch(ugraph)
  local distances = {}
  local vertices = ugraph.vertices
  local arcs = ugraph.arcs

  for _,v in ipairs(vertices) do
    distances[v] = {}
    local dist = distances[v]
    for _,w in ipairs(vertices) do
      dist[w] = #vertices +1
    end
    dist[v] = 0
  end
  local n = 1
  local p = Preprocessing.overExactlyNPairs(vertices, arcs, n)
  while (#p > 0) do
    for _, v in ipairs(p) do
      local tab = distances[v.tail]
      tab[v.head] = n
    end
    n = n + 1
    p = Preprocessing.overExactlyNPairs(vertices, arcs, n)
  end
  return(distances)
end


-- This function performs Dijkstra's algorithm on the graph.
--
-- @param ugraph The graph where the paths should be found
-- @param source The source vertex
--
-- @return |distance| A table holding every vertex $v$ as key and a table as
--                    value. The value table holds all other vertices $u$ as
--                    keys and their shortest distance to $v$ as value
-- @return |levels| A table holding the levels of the graph as keys and a
--                  table holding the vertices found on that level as values
-- @return |parent| A table holding each vertex as key and it's parent vertex
--                  as value

function PathLengths:dijkstra(ugraph, source)
  local distance = {}
  local levels = {}
  local parent = {}

  local queue = PriorityQueue.new()

  -- reset the distance of all nodes and insert them into the priority queue
  for _,v in ipairs(ugraph.vertices) do
    if v == source then
      distance[v] = 0
      parent[v] = nil
      queue:enqueue(v, distance[v])
    else
      distance[v] = #ugraph.vertices + 1 -- this is about infinity ;)
      queue:enqueue(v, distance[v])
    end
  end

  while not queue:isEmpty() do
    local u = queue:dequeue()

    assert(distance[u] < #ugraph.vertices + 1, 'the graph is not connected, Dijkstra will not work')

    if distance[u] > 0 then
      levels[distance[u]] = levels[distance[u]] or {}
      table.insert(levels[distance[u]], u)
    end



    for _,edge in ipairs(ugraph:outgoing(u)) do
      local v = edge.head
      local alternative = distance[u] + 1
      if alternative < distance[v] then
        distance[v] = alternative

        parent[v] = u

        -- update the priority of v
        queue:updatePriority(v, distance[v])
      end
    end
  end

  return distance, levels, parent
end

-- This function finds the pseudo diameter of the graph, which is the longest
-- shortest path in the graph
--
-- @param ugraph The graph who's pseudo diameter is wanted
--
-- @ return |diameter| The pseudo diameter of the graph
-- @ return |start_node| The start node of the longest shortest path in the
--                       graph
-- @ return |end_node| The end node of the longest shortest path in the graph

function PathLengths:pseudoDiameter(ugraph)

  -- find a node with minimum degree
  local start_node = ugraph.vertices[1]
  for _,v in ipairs(ugraph.vertices) do
    if #ugraph:incoming(v) + #ugraph:outgoing(v) < #ugraph:incoming(start_node) + #ugraph:outgoing(start_node) then
      start_node = v
    end
  end

  assert(start_node)

  local old_diameter = 0
  local diameter = 0
  local end_node = nil

  while true do
    local distance, levels = self:dijkstra(ugraph, start_node)

    -- the number of levels is the same as the distance of the nodes
    -- in the last level to the start node
    old_diameter = diameter
    diameter = #levels

    -- abort if the diameter could not be improved
    if diameter == old_diameter then
      end_node = levels[#levels][1]
      break
    end

    -- select the node with the smallest degree from the last level as
    -- the start node for the next iteration
    start_node = levels[#levels][1]
    for _,node in ipairs(levels[#levels]) do
      if #ugraph:incoming(node)+#ugraph:outgoing(node) < #ugraph:incoming(start_node) +  #ugraph:outgoing(start_node) then
        start_node = node
      end
    end

    assert(start_node)
  end

  assert(start_node)
  assert(end_node)

  return diameter, start_node, end_node
end

return PathLengths