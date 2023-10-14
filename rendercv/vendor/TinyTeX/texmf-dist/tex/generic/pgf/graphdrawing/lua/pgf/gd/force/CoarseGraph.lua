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


--- A class for handling "coarse" versions of a graph. Such versions contain
-- less nodes and edges than the original graph while retaining the overall
-- structure.

local Graph = require "pgf.gd.deprecated.Graph"   -- we subclass from here
local CoarseGraph = Graph.new()
CoarseGraph.__index = CoarseGraph



-- Namespace:
local force = require "pgf.gd.force"
force.CoarseGraph = CoarseGraph


-- Imports
local Node = require "pgf.gd.deprecated.Node"
local Edge = require "pgf.gd.deprecated.Edge"

local lib = require "pgf.gd.lib"


-- Class setup

CoarseGraph.COARSEN_INDEPENDENT_EDGES = 0  -- TT: Remark: These uppercase constants are *ugly*. Why do people do this?!
CoarseGraph.COARSEN_INDEPENDENT_NODES = 1
CoarseGraph.COARSEN_HYBRID = 2



--- Creates a new coarse graph derived from an existing graph.
--
-- Generates a coarse graph for the input |Graph|.
--
-- Coarsening describes the process of reducing the amount of nodes in a graph
-- by merging nodes into supernodes. There are different strategies, called
-- schemes, that can be applied, like merging nodes that belong to edges in a
-- maximal independent edge set or by creating supernodes based on a maximal
-- independent node set.
--
-- Coarsening is not performed automatically. The functions |CoarseGraph:coarsen|
-- and |CoarseGraph:interpolate| can be used to further coarsen the graph or
-- to restore the previous state (while interpolating the node positions from
-- the coarser version of the graph).
--
-- Note, however, that the input \meta{graph} is always modified in-place, so
-- if the original version of \meta{graph} is needed in parallel to its
-- coarse representations, a deep copy of \meta{graph} needs to be passed over
-- to |CoarseGraph.new|.
--
-- @param graph  An existing graph that needs to be coarsened.
-- @param scheme Coarsening scheme to use. Possible values are:\par
--               |CoarseGraph.COARSEN_INDEPENDENT_EDGES|:
--                 Coarsen the input graph by computing a maximal independent edge set
--                 and collapsing edges from this set. The resulting coarse graph has
--                 at least 50% of the nodes of the input graph. This coarsening scheme
--                 gives slightly better results than
--                 |CoarseGraph.COARSEN_INDEPENDENT_NODES| because it is less aggressive.
--                 However, this comes at higher computational cost.\par
--               |CoarseGraph.COARSEN_INDEPENDENT_NODES|:
--                 Coarsen the input graph by computing a maximal independent node set,
--                 making nodes from this set supernodes in the coarse graph, merging
--                 adjacent nodes into the supernodes and connecting the supernodes
--                 if their graph distance is no greater than three. This scheme gives
--                 slightly worse results than |CoarseGraph.COARSEN_INDEPENDENT_EDGES|
--                 but is computationally more efficient.\par
--               |CoarseGraph.COARSEN_HYBRID|: Combines the other schemes by starting
--                 with |CoarseGraph.COARSEN_INDEPENDENT_EDGES| and switching to
--                 |CoarseGraph.COARSEN_INDEPENDENT_NODES| as soon as the first scheme
--                 does not reduce the amount of nodes by a factor of 25%.
--
function CoarseGraph.new(graph, scheme)
  local coarse_graph = {
    graph = graph,
    level = 0,
    scheme = scheme or CoarseGraph.COARSEN_INDEPENDENT_EDGES,
    ratio = 0,
  }
  setmetatable(coarse_graph, CoarseGraph)
  return coarse_graph
end



local function custom_merge(table1, table2, first_metatable)
  local result = table1 and lib.copy(table1) or {}
  local first_metatable = first_metatable == true or false

  for key, value in pairs(table2) do
    if not result[key] then
      result[key] = value
    end
  end

  if not first_metatable or not getmetatable(result) then
    setmetatable(result, getmetatable(table2))
  end

  return result
end


local function pairs_by_sorted_keys (t, f)
  local a = {}
  for n in pairs(t) do a[#a + 1] = n end
  table.sort (a, f)
  local i = 0
  return function ()
    i = i + 1
    return a[i], t[a[i]]
  end
end



function CoarseGraph:coarsen()
  -- update the level
  self.level = self.level + 1

  local old_graph_size = #self.graph.nodes

  if self.scheme == CoarseGraph.COARSEN_INDEPENDENT_EDGES then
    local matching, unmatched_nodes = self:findMaximalMatching()

    for _,edge in ipairs(matching) do
      -- get the two nodes of the edge that we are about to collapse
      local u, v = edge.nodes[1], edge.nodes[2]

      assert(u ~= v, 'the edge ' .. tostring(edge) .. ' is a loop. loops are not supported by this algorithm')

      -- create a supernode
      local supernode = Node.new{
        name = '(' .. u.name .. ':' .. v.name .. ')',
        weight = u.weight + v.weight,
        subnodes = { u, v },
        subnode_edge = edge,
        level = self.level,
      }

      -- add the supernode to the graph
      self.graph:addNode(supernode)

      -- collect all neighbors of the nodes to merge, create a node -> edge mapping
      local u_neighbours = lib.map(u.edges, function(edge) return edge, edge:getNeighbour(u) end)
      local v_neighbours = lib.map(v.edges, function(edge) return edge, edge:getNeighbour(v) end)

      -- remove the two nodes themselves from the neighbor lists
      u_neighbours = lib.map(u_neighbours, function (edge,node) if node ~= v then return edge,node end end)
      v_neighbours = lib.map(v_neighbours, function (edge,node) if node ~= u then return edge,node end end)

      -- compute a list of neighbors u and v have in common
      local common_neighbours = lib.map(u_neighbours,
        function (edge,node)
        if v_neighbours[node] ~= nil then return edge,node end
      end)

      -- create a node -> edges mapping for common neighbors
      common_neighbours = lib.map(common_neighbours, function (edge, node)
        return { edge, v_neighbours[node] }, node
      end)

      -- drop common edges from the neighbor mappings
      u_neighbours = lib.map(u_neighbours, function (val,node) if not common_neighbours[node] then return val,node end end)
      v_neighbours = lib.map(v_neighbours, function (val,node) if not common_neighbours[node] then return val,node end end)

      -- merge neighbor lists
      local disjoint_neighbours = custom_merge(u_neighbours, v_neighbours)

      -- create edges between the supernode and the neighbors of the merged nodes
      for neighbour, edge in pairs_by_sorted_keys(disjoint_neighbours, function (n,m) return n.index < m.index end) do

        -- create a superedge to replace the existing one
        local superedge = Edge.new{
          direction = edge.direction,
          weight = edge.weight,
          subedges = { edge },
          level = self.level,
        }

        -- add the supernode and the neighbor to the edge
        if u_neighbours[neighbour] then
          superedge:addNode(neighbour)
          superedge:addNode(supernode)

        else
          superedge:addNode(supernode)
          superedge:addNode(neighbour)

        end

        -- replace the old edge
        self.graph:addEdge(superedge)
        self.graph:deleteEdge(edge)
      end

      -- do the same for all neighbors that the merged nodes have
      -- in common, except that the weights of the new edges are the
      -- sums of the of the weights of the edges to the common neighbors
      for neighbour, edges in pairs_by_sorted_keys(common_neighbours, function (n,m) return n.index < m.index end) do
        local weights = 0
        for _,e in ipairs(edges) do
          weights = weights + edge.weight
        end

        local superedge = Edge.new{
          direction = Edge.UNDIRECTED,
          weight = weights,
          subedges = edges,
          level = self.level,
        }

        -- add the supernode and the neighbor to the edge
        superedge:addNode(supernode)
        superedge:addNode(neighbour)

        -- replace the old edges
        self.graph:addEdge(superedge)
        for _,edge in ipairs(edges) do
          self.graph:deleteEdge(edge)
        end
      end

      -- delete the nodes u and v which were replaced by the supernode
      assert(#u.edges == 1, 'node ' .. u.name .. ' is part of a multiedge') -- if this fails, then there is a multiedge involving u
      assert(#v.edges == 1, 'node ' .. v.name .. ' is part of a multiedge') -- same here
      self.graph:deleteNode(u)
      self.graph:deleteNode(v)
    end
  else
    assert(false, 'schemes other than CoarseGraph.COARSEN_INDEPENDENT_EDGES are not implemented yet')
  end

  -- calculate the number of nodes ratio compared to the previous graph
  self.ratio = #self.graph.nodes / old_graph_size
end



function CoarseGraph:revertSuperedge(superedge)
  -- TODO we can probably skip adding edges that have one or more
  -- subedges with the same level. But that needs more testing.

  -- TODO we might have to pass the corresponding supernode to
  -- this method so that we can move subnodes to the same
  -- position, right? Interpolating seems to work fine without
  -- though...

  if #superedge.subedges == 1 then
    local subedge = superedge.subedges[1]

    if not self.graph:findNode(subedge.nodes[1].name) then
      self.graph:addNode(subedge.nodes[1])
    end

    if not self.graph:findNode(subedge.nodes[2].name) then
      self.graph:addNode(subedge.nodes[2])
    end

    if not self.graph:findEdge(subedge) then
      subedge.nodes[1]:addEdge(subedge)
      subedge.nodes[2]:addEdge(subedge)
      self.graph:addEdge(subedge)
    end

    if subedge.level and subedge.level >= self.level then
      self:revertSuperedge(subedge)
    end
  else
    for _,subedge in ipairs(superedge.subedges) do
      if not self.graph:findNode(subedge.nodes[1].name) then
        self.graph:addNode(subedge.nodes[1])
      end

      if not self.graph:findNode(subedge.nodes[2].name) then
        self.graph:addNode(subedge.nodes[2])
      end

      if not self.graph:findEdge(subedge) then
        subedge.nodes[1]:addEdge(subedge)
        subedge.nodes[2]:addEdge(subedge)
        self.graph:addEdge(subedge)
      end

      if subedge.level and subedge.level >= self.level then
        self:revertSuperedge(subedge)
      end
    end
  end
end



function CoarseGraph:interpolate()
  -- FIXME TODO Jannis: This does not work now that we allow multi-edges
  -- and loops! Reverting generates the same edges multiple times which leads
  -- to distorted drawings compared to the awesome results we had before!

  local nodes = lib.copy(self.graph.nodes)

  for _,supernode in ipairs(nodes) do
    assert(not supernode.level or supernode.level <= self.level)

    if supernode.level and supernode.level == self.level then
      -- move the subnode to the position of the supernode and add it to the graph
      supernode.subnodes[1].pos.x = supernode.pos.x
      supernode.subnodes[1].pos.y = supernode.pos.y

      if not self.graph:findNode(supernode.subnodes[1].name) then
        self.graph:addNode(supernode.subnodes[1])
      end

      -- move the subnode to the position of the supernode and add it to the graph
      supernode.subnodes[2].pos.x = supernode.pos.x
      supernode.subnodes[2].pos.y = supernode.pos.y

      if not self.graph:findNode(supernode.subnodes[2].name) then
        self.graph:addNode(supernode.subnodes[2])
      end

      if not self.graph:findEdge(supernode.subnode_edge) then
        supernode.subnodes[1]:addEdge(supernode.subnode_edge)
        supernode.subnodes[2]:addEdge(supernode.subnode_edge)
        self.graph:addEdge(supernode.subnode_edge)
      end

      local superedges = lib.copy(supernode.edges)

      for _,superedge in ipairs(superedges) do
        self:revertSuperedge(superedge)
      end

      self.graph:deleteNode(supernode)
    end
  end

  -- Make sure that the nodes and edges are in the correct order:
  table.sort (self.graph.nodes, function (a, b) return a.index < b.index end)
  table.sort (self.graph.edges, function (a, b) return a.index < b.index end)
  for _, n in pairs(self.graph.nodes) do
     table.sort (n.edges,  function (a, b) return a.index < b.index end)
  end

  -- update the level
  self.level = self.level - 1
end



function CoarseGraph:getSize()
  return #self.graph.nodes
end



function CoarseGraph:getRatio()
  return self.ratio
end



function CoarseGraph:getLevel()
  return self.level
end



function CoarseGraph:getGraph()
  return self.graph
end



function CoarseGraph:findMaximalMatching()
  local matching = {}
  local matched_nodes = {}
  local unmatched_nodes = {}

  -- iterate over nodes in random order
  for _,j in ipairs(lib.random_permutation(#self.graph.nodes)) do
    local node = self.graph.nodes[j]
    -- ignore nodes that have already been matched
    if not matched_nodes[node] then
      -- mark the node as matched
      matched_nodes[node] = true

      -- filter out edges adjacent to neighbors already matched
      local edges = lib.imap(node.edges,
        function (edge)
          if not matched_nodes[edge:getNeighbour(node)] then return edge end
        end)

      -- FIXME TODO We use a light-vertex matching here. This is
      -- different from the algorithm proposed by Hu which collapses
      -- edges based on a heavy-edge matching...
      if #edges > 0 then
        -- sort edges by the weights of the node's neighbors
        table.sort(edges, function (a, b)
          return a:getNeighbour(node).weight < b:getNeighbour(node).weight
        end)

        -- match the node against the neighbor with minimum weight
        matched_nodes[edges[1]:getNeighbour(node)] = true
        table.insert(matching, edges[1])
      end
    end
  end

  -- generate a list of nodes that were not matched at all
  for _,j in ipairs(lib.random_permutation(#self.graph.nodes)) do
    local node = self.graph.nodes[j]
    if not matched_nodes[node] then
      table.insert(unmatched_nodes, node)
    end
  end

  return matching, unmatched_nodes
end


-- done

return CoarseGraph
