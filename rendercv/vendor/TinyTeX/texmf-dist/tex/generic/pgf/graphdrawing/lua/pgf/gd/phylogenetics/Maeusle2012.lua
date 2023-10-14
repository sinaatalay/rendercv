-- Copyright 2013 by Sarah Mäusle and Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Imports
local Digraph               = require 'pgf.gd.model.Digraph'
local Coordinate            = require 'pgf.gd.model.Coordinate'
local Path                  = require 'pgf.gd.model.Path'

local layered               = require 'pgf.gd.layered'

local lib                   = require 'pgf.gd.lib'

local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare



-- Main class of this file:

local Maeusle2012 = lib.class {}

-- Namespace
require("pgf.gd.phylogenetics").Maeusle2012 = Maeusle2012




---
declare {
  key = "rooted rectangular phylogram",
  algorithm = {
    base_class = Maeusle2012,
    run = function (self)
      local root = self:getRoot()
      self:setPosForRectangularLayout(root)
    end
  },
  phase = "phylogenetic tree layout",
  phase_default = true,

  summary = [["
    A rooted rectangular phylogram is...
  "]],
  documentation = [["
    ...
  "]],
  examples = [["
    \tikz \graph [phylogenetic tree layout,
                  rooted rectangular phylogram,
                  balanced minimum evolution,
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

---
declare {
  key = "rectangular phylogram",
  use = { { key = "rooted rectangular phylogram" } },
  summary = "An alias for |rooted rectangular phylogram|"
}

---
declare {
  key = "rooted straight phylogram",
  algorithm = {
    base_class = Maeusle2012,
    run = function (self)
        local root = self:getRoot()
        self:setXPos(root)
        self:setYPosForStraightLayout(root)
      end
  },
  phase = "phylogenetic tree layout",

  summary = [["
    A rooted straight phylogram is...
  "]],
  documentation = [["
    ...
  "]],
  examples = [["
    \tikz \graph [phylogenetic tree layout,
                  rooted straight phylogram,
                  balanced minimum evolution, grow=right,
                  distance matrix={
                    0 4 9 9 9 9 9
                    4 0 9 9 9 9 9
                    9 9 0 2 7 7 7
                    9 9 2 0 7 7 7
                    9 9 7 7 0 3 5
                    9 9 7 7 3 0 5
                    9 9 7 7 5 5 0}]
      { a, b, c, d, e, f, g };
  "]]}

---
declare {
  key = "straight phylogram",
  use = { { key = "rooted straight phylogram" } },
  summary = "An alias for |rooted straight phylogram|"
}

---
declare {
  key = "unrooted rectangular phylogram",
  algorithm = {
    base_class = Maeusle2012,
    run = function (self)
        local root1, root2 = self:getRoot()
        self:setPosForUnrootedRectangular(root2, root1)
      end
  },
  phase = "phylogenetic tree layout",

  summary = [["
    A unrooted rectangular phylogram is...
  "]],
  documentation = [["
    ...
  "]],
  examples = [["
    \tikz \graph [phylogenetic tree layout,
                  unrooted rectangular phylogram,
                  balanced minimum evolution, grow=right,
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

---
declare {
  key = "unrooted straight phylogram",
  algorithm = {
    base_class = Maeusle2012,
    run = function (self)
        local root1, root2 = self:getRoot()
        self:setPosForUnrootedStraight(root2, root1)
      end
  },
  phase = "phylogenetic tree layout",

  summary = [["
    A unrooted straight phylogram is...
  "]],
  documentation = [["
    ...
  "]],
  examples = [["
    \tikz \graph [phylogenetic tree layout,
                  unrooted straight phylogram,
                  balanced minimum evolution, grow=right,
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


---
declare {
  key = "evolutionary unit length",
  type = "length",
  initial = "1cm",

  summary = [["
    Specifies how long a ``unit'' of evolutionary time should be on
    paper. For instance, if two nodes in a phylogenetic tree have an
    evolutionary distance of 3 and this length is set to |1cm|, then
    they will be |3cm| apart in a straight-line phylogram.
  "]],
  documentation = [["
    (This key used to be called |distance scaling factor|.)
  "]],
}



--
--  Gets the edge length between two nodes
--
--  @param vertex1, vertex2 The two nodes
--
--  @return The length of the edge between the two nodes
function Maeusle2012:edgeLength(vertex1, vertex2)
  return self.lengths[vertex1][vertex2]
end


-- Sets the x and y coordinates for all nodes, using a depth first
--  search
--
--  @param vertex The starting point; should usually be the root
--  @param values Values needed for the recursion
--  @param vertex2 A node that will not be visited; this parameter should only be set
--    for an unrooted layout to ensure that only the half of the tree is set.
function Maeusle2012:setPosForRectangularLayout(vertex, values, vertex2)
  local arcs = self.tree.arcs
  local vertices = self.tree.vertices
  local adjusted_bb = self.main_algorithm.adjusted_bb

  values = values or {
    length = 0, -- current path length
    visited = {}, -- all nodes that have already been visited
    leaves = {}, -- all leaves from left to right
  }

  local vertex_is_leaf = true
  values.visited[vertex] = true

  local children = {} -- a table containing all children of the
  -- current vertex (for the later determination of inner vertices
  -- x-positions)


  for _, arc in ipairs (self.tree:outgoing(vertex)) do
    if not values.visited[arc.head] and arc.head ~= vertex2 then
      -- if arc.head hasn't been visited, the current vertex cannot be a leaf
      vertex_is_leaf = false
      local arc_length = self:edgeLength(vertex, arc.head)

      values.length = values.length + arc_length

      -- go deeper
      self:setPosForRectangularLayout(arc.head, values, vertex2)

      -- get the children of the current vertex
      children[#children+1] = arc.head

      values.length = values.length - arc_length
    end
  end

  if vertex_is_leaf then
    -- subtract layer_pre, thus the leaf itself is NOT part of the
    -- edge length
    vertex.pos.y = - adjusted_bb[vertex].layer_pre

    values.leaves[#values.leaves+1] = vertex

    -- x coordinate:
    -- the x coordinates of the leaves are the first to be set; the
    -- first leave stays at x = 0, the x coordinates for the other
    -- leaves is computed with help of the ideal_sibling_distance
    -- function
    if #values.leaves > 1 then
      local left_sibling = values.leaves[#values.leaves-1]
      local ideal_distance = layered.ideal_sibling_distance(adjusted_bb, self.tree, vertex, left_sibling )
      vertex.pos.x = left_sibling.pos.x + ideal_distance
    end

  else -- the vertex is an inner node
    -- the x position of an inner vertex is at the center of its children.

    -- determine the outer children
    local left_child = children[1]
    local right_child = left_child
    for _, child in ipairs(children) do
      if child.pos.x < left_child.pos.x then left_child = child end
      if child.pos.x > right_child.pos.x then right_child = child end
    end

    -- position between child with highest and child with lowest x-value,
    -- if number of children is even
    local index_of_middle_child = math.ceil(#children/2)
    local even = #children/2 == index_of_middle_child

    if even then
      vertex.pos.x = (left_child.pos.x + right_child.pos.x) / 2
      index_of_middle_child = 0
    else -- if number of children is odd, position above the middle child
      vertex.pos.x = children[index_of_middle_child].pos.x
      table.remove(children, index_of_middle_child) -- don't bend the edge to this node, as it it above it anyway
    end
  end

  -- set the node's y-coordinate, using the calculated length
  -- and a scaling factor
  vertex.pos.y = vertex.pos.y + (values.length * self.tree.options['evolutionary unit length'])

  -- if this is the second subtree to be set of an unrooted tree, have
  -- it grow in the other direction
  if values.second_subtree then
    vertex.pos.y = -vertex.pos.y
  end

  -- bend the edges for the rectangular layout
  for i,child in ipairs(children) do
    self:bendEdge90Degree(child, vertex)
  end

  return values
end


-- Sets only the x-positions of all nodes using a depth-first search.
--  This is necessary for straight-edge layouts.
--
--  @param vertex The starting point of the depth-first search; should usually be the root
--  @param values Values needed for the recursion
--  @param vertex2 A node that will not be visited; this parameter should only be set
--    for an unrooted layout to ensure that only the half of the tree is set.
function Maeusle2012:setXPos(vertex, values, vertex2)
  local arcs = self.tree.arcs
  local vertices = self.tree.vertices
  if not values then
    values = {
      visited = {}, -- all nodes that have already been visited
      leaves = {}, -- all leaves from left to right
    }
  end

  local vertex_is_leaf = true
  values.visited[vertex] = true
  local children = {} -- a table containing all children of the current vertex (for the later determination of inner vertices x-positions)

  for _, arc in ipairs (self.tree:outgoing(vertex)) do
    if not values.visited[arc.head] and arc.head ~= vertex2 then
      -- if arc.head hasn't been visited, the current vertex cannot be a leaf
      vertex_is_leaf = false

      -- go deeper
      self:setXPos(arc.head, values, vertex2)

      -- get the children of the current vertex
      table.insert(children, arc.head)
    end
  end

  -- set the x-position of a leaf
  if vertex_is_leaf then

    table.insert(values.leaves, vertex)

    if #values.leaves > 1 then
      local left_sibling = values.leaves[#values.leaves-1]
      local ideal_distance = layered.ideal_sibling_distance(self.main_algorithm.adjusted_bb, self.tree, vertex, left_sibling )
      vertex.pos.x = left_sibling.pos.x + ideal_distance
    end

  -- set x position of an inner node, which is at the center of its
  -- children
  else
    -- determine the outer children
    local left_child = children[1]
    local right_child = left_child
    for _, child in ipairs(children) do
      if child.pos.x < left_child.pos.x then left_child = child end
      if child.pos.x > right_child.pos.x then right_child = child end
    end

    -- position between child with highest and child with lowest x-value,
    -- if number of children is even
    local index_of_middle_child = math.ceil(#children/2)
    local even = #children/2 == index_of_middle_child

    if even then
      vertex.pos.x = (left_child.pos.x + right_child.pos.x) / 2
    else -- if number of children is odd, position above the middle child
      vertex.pos.x = children[index_of_middle_child].pos.x
    end
  end
  return values
end


--
-- Sets only the y-positions of all nodes using a depth-first search.
-- This is needed for a straight-edge layout, as the x-positions have
-- to bet first so that the y-coordinates can be calculated correctly
-- here.
--
-- @param vertex1 The starting point of the depth-first search
-- @param values Values needed for the recursion
-- @param vertex2 For unrooted layout only: The root of the second subtree.
-- This node and all its children will not be visited.
function Maeusle2012:setYPosForStraightLayout(vertex, values, vertex2)
  local arcs = self.tree.arcs
  local vertices = self.tree.vertices
  local adjusted_bb = self.main_algorithm.adjusted_bb

  values = values or {
    length = 0, -- current path length
    visited = {}, -- all nodes that have already been visited
    leaves = {}, -- all leaves from left to right
  }

  local vertex_is_leaf = true
  values.visited[vertex] = true
  local children = {} -- a table containing all children of the current vertex (for the later determination of inner vertices x-positions)

  for _, arc in ipairs (self.tree:outgoing(vertex)) do
    if not values.visited[arc.head] and arc.head ~= vertex2 then
      -- if arc.head hasn't been visited, the current vertex cannot be a leaf
      vertex_is_leaf = false

      -- calculate the arc length with the help of the Pythagorean
      -- theorem
      local a
      local l = self:edgeLength(vertex, arc.head) * self.tree.options['evolutionary unit length']
      local b = math.abs(vertex.pos.x - arc.head.pos.x)
      if b > l then
        a = 0
      else
        a = math.sqrt(l^2-b^2)
      end
      local arc_length = a


      values.length = values.length + arc_length

      -- go deeper
      self:setYPosForStraightLayout(arc.head, values, vertex2)

      -- get the children of the current vertex
      table.insert(children, arc.head)

      values.length = values.length - arc_length
    end
  end

  if vertex_is_leaf then
    -- subtract layer_pre, thus the leaf itself is NOT part of the
    -- edge length
    vertex.pos.y = - adjusted_bb[vertex].layer_pre

    table.insert(values.leaves, vertex)
  end

  -- set the node's y-coordinate, using the calculated length
  vertex.pos.y = vertex.pos.y + values.length

  -- if this is the second subtree to be set of an unrooted tree, have
  -- it grow in the other direction
  if values.second_subtree then vertex.pos.y = -vertex.pos.y end
end

--
-- Correct the x-positions in the unrooted layout for a more aesthetic result
--
-- If the roots of the two subtrees have different x-positions, this is corrected
-- by shifting the x-positions of all nodes in one subtree by that difference.
--
-- @param vertex1 The root of the first subtree
-- @param vertex2 The root of the second subtree.
function Maeusle2012:correctXPos(vertex1, vertex2, straight)

  -- correct the x-positions
  --
  -- @param vertex Starting point of the depth-first search
  -- @param values Values needed for the recursion
  -- @param vertex2 The root of the subtree that will not be visited
  local function x_correction(vertex, values, vertex2)
    values.visited[vertex] = true
    local children = {}

    for _, arc in ipairs (self.tree:outgoing(vertex)) do
      if not values.visited[arc.head] and arc.head ~= vertex2 then

        table.insert(children, arc.head)
        x_correction(arc.head, values, vertex2)
      end
    end

    vertex.pos.x = vertex.pos.x + values.diff
    if not straight then
      for i,child in ipairs(children) do
        self:bendEdge90Degree(child, vertex)
      end
    end

    return values
  end

  -- compute the difference of the x-positions of the two subtrees'
  -- roots
  local diff = vertex1.pos.x - vertex2.pos.x
  local values = { visited = {} }
  if diff < 0 then
    values.diff = - diff
    x_correction(vertex1, values, vertex2)
  elseif diff > 0 then
    values.diff = diff
    x_correction(vertex2, values, vertex1)
  end
end


--
--  Sets the x- and y-positions of the vertices in an unrooted layout
--
--  This is done using the function for setting the positions for a rooted layout:
--  Two neighboring vertices are chosen as roots; one half of the tree
--  is drawn in one direction, the other half 180° to the other
--  direction.
--
-- @param vertex1, vertex2: The vertices functioning as roots
function Maeusle2012:setPosForUnrootedRectangular(vertex1, vertex2)
  -- set positions for first half of the tree...
  self:setPosForRectangularLayout(vertex2,false,vertex1)
  local vals={
    length = self:edgeLength(vertex1, vertex2), -- the length between the two roots
    visited={},
    leaves={},
    path={},
    second_subtree = true
  }
  -- ... and for the second half.
  self:setPosForRectangularLayout(vertex1,vals,vertex2)
  -- if the two roots have different x-values, correct the x-positions for nicer layout
  self:correctXPos(vertex1, vertex2, false)
end


--
--  Sets the x- and y-positions of the vertices in an unrooted straight layout
--
--  This is done using the function for setting the positions for a rooted straight layout:
--  Two neighboring vertices are chosen as roots; one half of the tree
--  is drawn in one direction, the other half 180° to the other
--  direction.
--
-- @param vertex1, vertex2: The vertices functioning as roots
function Maeusle2012:setPosForUnrootedStraight(vertex1, vertex2)
  -- first set the x-positions of the two subtrees...
  local vals = {visited = {}, leaves = {} }
  self:setXPos(vertex2, vals, vertex1)
  self:setXPos(vertex1, vals, vertex2)

  -- ... and then the y-positions
  self:setYPosForStraightLayout(vertex2, false, vertex1)
  local vals={
    length = self:edgeLength(vertex1, vertex2) * self.tree.options['evolutionary unit length'],
    visited={},
    leaves={},
    path={},
    second_subtree = true
  }
  self:setYPosForStraightLayout(vertex1, vals, vertex2)

  -- if the two roots have different x-values, correct the x-positions for nicer layout
  -- as the length between the roots of the two subtrees is set to the calculated value,
  -- this step is mandatory for the unrooted, straight layout
  self:correctXPos(vertex1, vertex2, true)
end



-- Bends the arc between two nodes by 90 degree by updating the arc's
--  path
--
--  @param head The head of the arc
--  @param tail The tail of the arc
function Maeusle2012:bendEdge90Degree(head, tail)
  local arc = self.tree:arc(tail,head)
  local syntactic_tail = arc:syntacticTailAndHead()
  arc:setPolylinePath { Coordinate.new(head.pos.x, tail.pos.y) }
end



-- Finds the longest path in a graph
--
--  @ return A table containing the path (an array of nodes) and the
--  path length
function Maeusle2012:findLongestPath()
  local starting_point = self.tree.vertices[1] -- begin at any vertex
  -- get the path lengths from the starting point to all leaves:
  local paths_to_leaves = self:getPathLengthsToLeaves(starting_point)
  local path_lengths = paths_to_leaves.path_lengths
  local paths = paths_to_leaves.paths

 -- looks for the longest path and identifies its end-point
  local function find_head_of_longest_path(path_lengths, paths)
    local longest_path
    local node
    -- to make sure that the same path is chosen every time, we go over all vertices with "ipairs"; if we would go over path_lengths directly, we could only use "pairs"
    for _, vertex in ipairs(self.tree.vertices) do
      local path_length = path_lengths[vertex]
      if path_length then
        -- choose longest path. if two paths have the same length, take the path with more nodes
        if not longest_path or path_length > longest_path or (path_length == longest_path and #paths[vertex]>#paths[node]) then
          longest_path = path_length
          node = vertex
        end
      end
    end
    return node
  end

  -- find the longest path leading away from the starting point and identify
  -- the leaf it leads to. Use that leaf as the tail for the next path
  -- search
  local tail = find_head_of_longest_path(path_lengths, paths)
  paths_to_leaves = self:getPathLengthsToLeaves(tail) -- gets new path information
  -- paths_to leaves now has all paths starting at vertex "tail"; one of these paths is the
  -- longest (globally)
  path_lengths = paths_to_leaves.path_lengths
  paths = paths_to_leaves.paths
  local head = find_head_of_longest_path(path_lengths, paths)

  local path_information =
   {  path = paths_to_leaves.paths[head], -- longest path
      length = path_lengths[head] } -- length of that path

  return path_information
end


-- a depth first search for getting all path lengths from a
--  starting point to all leaves
--
--  @param vertex The vertex where the search is to start
--  @param values Table of values needed for the recursive computation
--
--  @return A table containing:
--          a table of the leaves with corresponding path lengths
--          and a table containing the path to each leaf (an array of
--          nodes)
function Maeusle2012:getPathLengthsToLeaves(vertex, values)
  local arcs = self.tree.arcs
  local vertices = self.tree.vertices
  if not values then
    values = {
      paths = {}, -- all paths we've found so far
      path_lengths = {}, -- all path lengths that have so far been computed
      length = 0, -- current path length
      visited = {}, -- all nodes that have already been visited
      path = {}, -- the current path we're on
      leaves = {} -- all leaves from left to right
    }
    table.insert(values.path,vertex)
  end

  local vertex_is_leaf = true
  values.visited[vertex] = true

  for _, arc in ipairs (self.tree:outgoing(vertex)) do
    if not values.visited[arc.head] then
      -- the current vertex is not a leaf! note: if the starting vertex is a leaf, vertex_is_leaf
      -- will be set to 'false' for it anyway. as we're not interested in the distance
      -- of the starting vertex to itself, this is fine.
      vertex_is_leaf = false
      local arc_length = self.lengths[vertex][arc.head]
      values.length = values.length + arc_length

      -- add arc.head to path...
      table.insert(values.path,arc.head)

      -- ... and go down that path
      self:getPathLengthsToLeaves(arc.head, values)

      -- remove arc.head again to go a different path
      table.remove(values.path)
      values.length = values.length - arc_length
    end
  end

  if vertex_is_leaf then -- we store the information gained on the path to this leaf
    values.path_lengths[vertex] = values.length
    values.paths[vertex] = {}
    table.insert(values.leaves, vertex)
    for i,k in pairs(values.path) do
      values.paths[vertex][i] = k
    end
  end
  -- the path_lengths and the paths are stored in one table and
  -- returned together
  local path_information =
    { path_lengths = values.path_lengths,
      paths = values.paths,
      leaves = values.leaves }
  return path_information
end


-- Gets the root of a tree
-- checks whether a tree is already rooted, if not, computeCenterOfPath() is
-- called, which defines a node in the center of the graph as the root
--
--  @return The root
function Maeusle2012:getRoot()
  -- check whether a root exists (vertex with degree 2)
  local root = lib.find (self.tree.vertices, function(v) return #self.tree:outgoing(v) == 2 end)
  if root then
    return root, self.tree:outgoing(root)[1].head
  else
    return self:computeCenterOfPath()
  end
end


--
--  @return The newly computed root and its nearest neighbor
function Maeusle2012:computeCenterOfPath()
  local longest_path = self:findLongestPath()
  local path = longest_path.path
  local root, neighbor_of_root

  local length = 0 --length between first vertex on the path and the current vertex we're looking at
  for i = 1, #path-1 do
    local node1 = path[i]
    local node2 = path[i+1]
    local node3 = path[i+2]

    local dist_node_1_2, dist_node_2_3 --distances between node1 and node2, and node2 and node3
    dist_node_1_2 = self:edgeLength(node1, node2)
    if node3 then dist_node_2_3 = self:edgeLength(node2, node3) end
    length = length + dist_node_1_2 -- length between first vertex on the path and current node2

    if length == longest_path.length/2 then
      root = node2 -- if there is a node exactly at the half of the path, use this node as root

      -- and find nearest neighbor of the root
      if node3 == nil or dist_node_1_2 < dist_node_2_3 then -- neu 3.8
        neighbor_of_root = node1
      else
        neighbor_of_root = node3
      end
      break

    elseif length > longest_path.length/2 then
      -- else find node closest to the center of the path and use it as the root;
      local node2_length = math.abs(longest_path.length/2 - length)
      local node1_length = math.abs(longest_path.length/2 - (length - dist_node_1_2))
      if node2_length < node1_length then
        root = node2
        neighbor_of_root = node1
        -- if node3 is closer to node2 than node1 is, use node3 as neighbor!
        if node3 and dist_node_2_3 < dist_node_1_2 then neighbor_of_root = node3 end
      else
        root = node1
        neighbor_of_root = node2
        --check if node i-1 is closer to node1
        local dist_node_0_1
        if i>1 then
          node0 = path[i-1]
          dist_node_0_1 = self:edgeLength(node0, node1)
          if dist_node_0_1 < dist_node_1_2 then neighbor_of_root = node0 end
        end
      end
      break
    end
  end

  return root, neighbor_of_root
end


return Maeusle2012
