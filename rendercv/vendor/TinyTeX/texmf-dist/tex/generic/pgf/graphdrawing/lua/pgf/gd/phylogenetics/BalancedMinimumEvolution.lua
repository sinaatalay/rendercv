-- Copyright 2013 by Sarah Mäusle and Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



local BalancedMinimumEvolution = {}


-- Namespace
require("pgf.gd.phylogenetics").BalancedMinimumEvolution = BalancedMinimumEvolution

-- Imports
local InterfaceToAlgorithms = require("pgf.gd.interface.InterfaceToAlgorithms")
local DistanceMatrix        = require("pgf.gd.phylogenetics.DistanceMatrix")
local Storage               = require("pgf.gd.lib.Storage")
local Digraph               = require("pgf.gd.model.Digraph")
local lib                   = require("pgf.gd.lib")

-- Shorthand:
local declare = InterfaceToAlgorithms.declare


---
declare {
  key = "balanced minimum evolution",
  algorithm = BalancedMinimumEvolution,
  phase = "phylogenetic tree generation",

  summary = [["
    The BME (Balanced Minimum Evolution) algorithm tries to minimize
    the total tree length.
  "]],
  documentation = [["
    This algorithm is from Desper and Gascuel, \emph{Fast and
    Accurate Phylogeny Reconstruction Algorithms Based on the
    Minimum-Evolution Principle}, 2002. The tree is built in a way
    that minimizes the total tree length. The leaves are inserted
    into the tree one after another, creating new edges and new
    nodes. After every insertion the distance matrix has to be
    updated.
  "]],
  examples = [["
    \tikz \graph [phylogenetic tree layout,
                  balanced minimum evolution,
                  grow'=right, sibling distance=0pt,
                  distance matrix={
                    0 4 9 9 9 9 9
                    4 0 9 9 9 9 9
                    9 9 0 2 7 7 7
                    9 9 2 0 7 7 7
                    9 9 7 7 0 3 5
                    9 9 7 7 3 0 5
                    9 9 7 7 5 5 0}]
      { a, b, c, d, e, f, g };
  "]]
}




function BalancedMinimumEvolution:run()

  self.tree = Digraph.new(self.main_algorithm.digraph)

  self.distances = Storage.newTableStorage()

  local vertices = self.tree.vertices

  -- Sanity checks:
  if #vertices == 2 then
    self.tree:connect(vertices[1],vertices[2])
    return self.tree
  elseif #vertices > 2 then

    -- Setup storages:
    self.is_leaf   = Storage.new()

    -- First, build the initial distance matrix:
    local matrix = DistanceMatrix.graphDistanceMatrix(self.tree)

    -- Store distance information in the distance fields of the storages:
    for _,u in ipairs(vertices) do
      for _,v in ipairs(vertices) do
        self.distances[u][v] = matrix[u][v]
      end
    end

    -- Run BME
    self:runBME()

    -- Run postoptimizations
    local optimization_class = self.tree.options.algorithm_phases['phylogenetic tree optimization']
    optimization_class.new {
      main_algorithm = self.main_algorithm,
      tree = self.tree,
      matrix = self.matrix,
      distances = self.distances,
      is_leaf = self.is_leaf,
    }:run()
  end

  -- Finish
  self:computeFinalLengths()
  self:createFinalEdges()

  return self.tree
end




-- the BME (Balanced Minimum Evolution) algorithm
-- [DESPER and GASCUEL: Fast and Accurate Phylogeny Reconstruction
-- Algorithms Based on the Minimum-Evolution Principle, 2002]
--
-- The tree is built in a way that minimizes the total tree length.
-- The leaves are inserted into the tree one after another, creating new edges and new nodes.
-- After every insertion the distance matrix has to be updated.
function BalancedMinimumEvolution:runBME()
  local g = self.tree
  local leaves = {}
  local is_leaf = self.is_leaf
  local distances = self.distances

  -- get user input
  for i, vertex in ipairs (g.vertices) do
    leaves[i] = vertex
    is_leaf[vertex] = true
  end

  -- create the new node which will be connected to the first three leaves
  local new_node = InterfaceToAlgorithms.createVertex(
    self.main_algorithm,
    {
      name = "BMEnode"..#g.vertices+1,
      generated_options = { { key = "phylogenetic inner node" } }
    }
  )
  g:add {new_node}
  -- set the distances of new_node to subtrees
  local distance_1_2 = self:distance(leaves[1],leaves[2])
  local distance_1_3 = self:distance(leaves[1],leaves[3])
  local distance_2_3 = self:distance(leaves[2],leaves[3])
  distances[new_node][leaves[1]] = 0.5*(distance_1_2 + distance_1_3)
  distances[new_node][leaves[2]] = 0.5*(distance_1_2 + distance_2_3)
  distances[new_node][leaves[3]] = 0.5*(distance_1_3 + distance_2_3)

  --connect the first three leaves to the new node
  for i = 1,3 do
    g:connect(new_node, leaves[i])
    g:connect(leaves[i], new_node)
  end

  for k = 4,#leaves do
    -- compute distance from k to any subtree
    local k_dists = Storage.newTableStorage()
    for i = 1,k-1 do
      -- note that the function called stores the k_dists before they are overwritten
      self:computeAverageDistancesToAllSubtreesForK(g.vertices[i], { }, k,k_dists)
    end

    -- find the best insertion point
    local best_arc = self:findBestEdge(g.vertices[1],nil,k_dists)
    local head = best_arc.head
    local tail = best_arc.tail

    -- remove the old arc
    g:disconnect(tail, head)
    g:disconnect(head, tail)

    -- create the new node
    local new_node = InterfaceToAlgorithms.createVertex(
      self.main_algorithm,
      {
        name = "BMEnode"..#g.vertices+1,
        generated_options = {
          { key = "phylogenetic inner node" }
        }
      }
    )
    g:add{new_node}

    -- gather the vertices that will be connected to the new node...
    local vertices_to_connect = { head, tail, leaves[k] }

    -- ...and connect them
    for _, vertex in pairs (vertices_to_connect) do
      g:connect(new_node, vertex)
      g:connect(vertex, new_node)
    end

    if not is_leaf[tail] then
      distances[leaves[k]][tail] = k_dists[head][tail]
    end
    if not is_leaf[head] then
      distances[leaves[k]][head] = k_dists[tail][head]
    end
    -- insert distances from k to subtrees into actual matrix...
    self:setAccurateDistancesForK(new_node,nil,k,k_dists,leaves)

    -- set the distance from k to the new node, which was created by inserting k into the graph
    distances[leaves[k]][new_node] = 0.5*( self:distance(leaves[k], head) + self:distance(leaves[k],tail))

    -- update the average distances
    local values = {}
    values.s = head -- s--u is the arc into which k has been inserted
    values.u = tail
    values.new_node = new_node -- the new node created by inserting k
    self:updateAverageDistances(new_node, values,k,leaves)
  end
end

--
--  Updates the average distances from k to all subtrees
--
--  @param vertex The starting point of the recursion
--  @param values The values needed for the recursion
--           - s, u     The nodes which span the edge into which k has been
--                      inserted
--           - new_node The new_node which has been created to insert k
--           - l        (l-1) is the number of edges between the
--                      new_node and the current subtree Y
--
--    values.new_node, values.u and values.s must be set
--    the depth first search must begin at the new node, thus vertex
--    must be set to the newly created node
function BalancedMinimumEvolution:updateAverageDistances(vertex, values, k, leaves)
  local g = self.tree
  local leaf_k = leaves[k]
  local y, z, x
  if not values.visited then
    values.visited = {}
    values.visited[leaf_k] = leaf_k -- we don't want to visit k!
  end
  -- there are (l-1) edges between new_node and y
  if not values.l then values.l = 1 end
  if not values.new_node then values.new_node = g:outgoing(leaf_k)[1].head end
  --values.s and values.u must be set

  -- the two nodes which connect the edge on which k was inserted: s,u

  local new_node = values.new_node
  local l = values.l
  local visited = values.visited

  visited[vertex] = vertex

  -- computes the distances to Y{k} for all subtrees X of Z
  function loop_over_x( x, y, values )
    local l = values.l
    local y1= values.y1

    -- calculate distance between Y{k} and X
    local old_distance -- the distance between Y{/k} and X needed for calculating the new distance
    if y == new_node then -- this y didn't exist in the former tree; so use y1 (see below)
       old_distance = self:distance(x,y1)
    else
      old_distance = self:distance(x,y)
    end

    local new_distance = old_distance + math.pow(2,-l) * ( self:distance(leaf_k,x) - self:distance(x,y1) )
    self.distances[x][y] = new_distance
    self.distances[y][x] = new_distance -- symmetric matrix

    values.x_visited[x] = x
    --go deeper to next x
    for _, x_arc in ipairs (self.tree:outgoing(x)) do
      if not values.x_visited[x_arc.head] then
        local new_x = x_arc.head
        loop_over_x( new_x, y, values )
      end
    end
  end

  --loop over Z's
  for _, arc in ipairs (self.tree:outgoing(vertex)) do
    if not visited[arc.head] then
      -- set y1, which is the node which was pushed further away from
      -- subtree Z by inserting k
      if arc.head == values.s then
        values.y1 = values.u
      elseif arc.head == values.u then
        values.y1 = values.s
      else
        assert(values.y1,"no y1 set!")
      end

      z = arc.head -- root of the subtree we're looking at
      y = arc.tail -- the root of the subtree-complement of Z

      x = z -- the first subtree of Z is Z itself
      values.x_visited = {}
      values.x_visited[y] = y -- we don't want to go there, as we want to stay within Z
      loop_over_x( z,y, values ) -- visit all possible subtrees of Z

      -- go to next Z
      values.l = values.l+1 -- moving further away from the new_node
      self:updateAverageDistances(z,values,k,leaves)
      values.l = values.l-1 -- moving back to the new_node
    end
  end
end


--
-- Computes the average distances of a node, which does not yet belong
-- to the graph, to all subtrees. This is done using a depth first
-- search
--
-- @param vertex The starting point of the depth first search
-- @param values The values for the recursion
--              - distances The table in which the distances are to be
--                stored
--              - outgoing_arcs The table containing the outgoing arcs
--                of the current vertex
--
-- @return The average distance of the new node #k to any subtree
--    The distances are stored as follows:
--    example: distances[center][a]
--             center is any vertex, thus if center is an inner vertex
--             it has 3 neighbors a,b and c, which can all be seen as the
--             roots of subtrees A,B,C.
--             distances[center][a] gives us the distance of the new
--             node k to the subtree A.
--             if center is a leaf, it has only one neighbor, which
--             can also be seen as the root of the subtree T\{center}
--
function BalancedMinimumEvolution:computeAverageDistancesToAllSubtreesForK(vertex, values, k, k_dists)
  local is_leaf = self.is_leaf
  local arcs = self.tree.arcs
  local vertices = self.tree.vertices
  local center_vertex = vertex
  -- for every vertex a table is created, in which the distances to all
  -- its subtrees will be stored

  values.outgoing_arcs = values.outgoing_arcs or self.tree:outgoing(center_vertex)
  for _, arc in ipairs (values.outgoing_arcs) do
    local root = arc.head -- this vertex can be seen as the root of a subtree
    if is_leaf[root] then -- we know the distance of k to the leaf!
      k_dists[center_vertex][root] = self:distance(vertices[k], root)
    else -- to compute the distance we need the root's neighboring vertices, which we can access by its outgoing arcs
      local arc1, arc2
      local arc_back -- the arc we came from
      for _, next_arc in ipairs (self.tree:outgoing(root)) do
        if next_arc.head ~= center_vertex then
          arc1 = arc1 or next_arc
          arc2 = next_arc
        else
          arc_back = next_arc
        end
      end

      values.outgoing_arcs = { arc1, arc2, arc_back }

      -- go deeper, if the distances for the next center node haven't been set yet
      if not (k_dists[root][arc1.head] and k_dists[root][arc2.head]) then
        self:computeAverageDistancesToAllSubtreesForK(root, values, k,k_dists)
      end

      -- set the distance between k and subtree
      k_dists[center_vertex][root] = 1/2 * (k_dists[root][arc1.head] + k_dists[root][arc2.head])
    end
  end
end


--
-- Sets the distances from k to subtrees
-- In computeAverageDistancesToAllSubtreesForK the distances to ALL possible
-- subtrees are computed. Once k is inserted many of those subtrees don't
-- exist  for k, as k is now part of them. In this  function all
-- still accurate subtrees and their distances to k are
-- extracted.
--
-- @param center The vertex serving as the starting point of the depth-first search;
-- should be the new_node

function BalancedMinimumEvolution:setAccurateDistancesForK(center,visited,k,k_dists,leaves)
  local visited = visited or {}
  local distances = self.distances

  visited[center] = center
  local outgoings = self.tree:outgoing(center)
  for _,arc in ipairs (outgoings) do
    local vertex = arc.head
    if vertex ~= leaves[k] then
      local distance
      -- set the distance
      if not distances[leaves[k]][vertex] and k_dists[center] then
        distance = k_dists[center][vertex] -- use previously calculated distance
        distances[leaves[k]][vertex] = distance
        distances[vertex][leaves[k]] = distance
      end
      -- go deeper
      if not visited[vertex] then
        self:setAccurateDistancesForK(vertex,visited,k,k_dists,leaves)
      end
    end
  end
end


--
--  Find the best edge for the insertion of leaf #k, such that the
--  total tree length is minimized. This function uses a depth first
--  search.
--
--  @param vertex The vertex where the depth first search is
--                started; must be a leaf
--  @param values The values needed for the recursion
--              - visited: The vertices that already have been visited
--              - tree_length: The current tree_length
--              - best_arc: The current best_arc, such that the tree
--                length is minimized
--              - min_length: The smallest tree_length found so far
function BalancedMinimumEvolution:findBestEdge(vertex, values, k_dists)
  local arcs = self.tree.arcs
  local vertices = self.tree.vertices
  values = values or { visited = {} }
  values.visited[vertex] = vertex

  local c -- the arc we came from
  local unvisited_arcs = {} --unvisited arcs
  --identify arcs
  for _, arc in ipairs (self.tree:outgoing(vertex)) do
    if not values.visited[arc.head] then
      unvisited_arcs[#unvisited_arcs+1] = arc
    else
      c = arc.head --last visited arc
    end
  end

  for i, arc in ipairs (unvisited_arcs) do
    local change_in_tree_length = 0
     -- set tree length to 0 for first insertion arc
    if not values.tree_length then
      values.tree_length = 0
      values.best_arc = arc
      values.min_length = 0
    else -- compute new tree length for the case that k is inserted into this arc
      local b = arc.head --current arc
      local a = unvisited_arcs[i%2+1].head -- the remaining arc
      local k_v = vertices[k] -- the leaf to be inserted
      change_in_tree_length = 1/4 * ( (   self:distance(a,c)
                                        + k_dists[vertex][b])
                                        - (self:distance(a,b)
                                        + k_dists[vertex][c]) )
      values.tree_length = values.tree_length + change_in_tree_length
    end
    -- if the tree length becomes shorter, this is the new best arc
    -- for the insertion of leaf k
    if values.tree_length < values.min_length then
      values.best_arc = arc
      values.min_length = values.tree_length
    end

    -- go deeper
    self:findBestEdge(arc.head, values, k_dists)

    values.tree_length = values.tree_length - change_in_tree_length
  end
  return values.best_arc
end

-- Calculates the total tree length
-- This is done by adding up all the edge lengths
--
-- @return the tree length
function BalancedMinimumEvolution:calculateTreeLength()
  local vertices = self.tree.vertices
  local sum = 0

  for index, v1 in ipairs(vertices) do
    for i = index+1,#vertices do
      local v2 = vertices[i]
      local dist = self.lengths[v1][v2]
      if dist then
        sum = sum + dist
      end
    end
  end
  return sum
end

-- generates edges for the final graph
--
-- throughout the process of creating the tree, arcs have been
-- disconnected and connected, without truly creating edges. this is
-- done in this function
function BalancedMinimumEvolution:createFinalEdges()
  local g = self.tree
  local o_arcs = {} -- copy arcs since createEdge is going to modify the arcs array...
  for _,arc in ipairs(g.arcs) do
    if arc.tail.event.index < arc.head.event.index then
      o_arcs[#o_arcs+1] = arc
    end
  end
  for _,arc in ipairs(o_arcs) do
    InterfaceToAlgorithms.createEdge(
      self.main_algorithm, arc.tail, arc.head,
      { generated_options = {
          { key = "phylogenetic edge", value = tostring(self.lengths[arc.tail][arc.head]) }
      }})
  end
end


-- Gets the distance between two nodes as specified in their options
--  or storage fields.
--  Note: this function implies that the distance from a to b is the
--  same as the distance from b to a.
--
--  @param a,b The nodes
--  @return The distance between the two nodes

function BalancedMinimumEvolution:distance(a, b)
  if a == b then
    return 0
  else
    local distances = self.distances
    return distances[a][b] or distances[b][a]
  end
end


--
-- computes the final branch lengths
--
--  goes over all arcs and computes the final branch lengths,
--  as neither the BME nor the BNNI main_algorithm does so.
function BalancedMinimumEvolution:computeFinalLengths()
  local is_leaf = self.is_leaf
  local lengths = self.lengths
  local g = self.tree
  for _, arc in ipairs(g.arcs) do
    local head = arc.head
    local tail = arc.tail
    local distance
    local a,b,c,d
    -- assert, that the length hasn't already been computed for this arc
    if not lengths[head][tail] then
      if not is_leaf[head] then
        -- define subtrees a and b
        for _, arc in ipairs (g:outgoing(head)) do
          local subtree = arc.head
          if subtree ~= tail then
            a = a or subtree
            b = subtree
          end
        end
      end
      if not is_leaf[tail] then
        -- define subtrees c and d
        for _, arc in ipairs (g:outgoing(tail)) do
          local subtree = arc.head
          if subtree ~= head then
            c = c or subtree
            d = subtree
          end
        end
      end
      -- compute the distance using the formula for outer or inner edges, respectively
      if is_leaf[head] then
        distance = 1/2 * (  self:distance(head,c)
                          + self:distance(head,d)
                          - self:distance(c,d)   )
      elseif is_leaf[tail] then
        distance = 1/2 * (  self:distance(tail,a)
                          + self:distance(tail,b)
                          - self:distance(a,b)   )
      else --inner edge
        distance = self:distance(head, tail)
                   -1/2 * (  self:distance(a,b)
                           + self:distance(c,d) )
      end
      lengths[head][tail] = distance
      lengths[tail][head] = distance
    end
  end

end



return BalancedMinimumEvolution
