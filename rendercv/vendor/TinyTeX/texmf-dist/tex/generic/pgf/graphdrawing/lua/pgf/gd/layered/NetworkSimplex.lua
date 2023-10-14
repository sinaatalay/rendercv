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




--- This file contains an implementation of the network simplex method
--- for node ranking and x coordinate optimization in layered drawing
--- algorithms, as proposed in
---
--- "A Technique for Drawing Directed Graphs"
--  by Gansner, Koutsofios, North, Vo, 1993.


local NetworkSimplex = {}
NetworkSimplex.__index = NetworkSimplex

-- Namespace
local layered = require "pgf.gd.layered"
layered.NetworkSimplex = NetworkSimplex


-- Imports
local DepthFirstSearch = require "pgf.gd.lib.DepthFirstSearch"
local Ranking          = require "pgf.gd.layered.Ranking"
local Graph            = require "pgf.gd.deprecated.Graph"
local lib              = require "pgf.gd.lib"



-- Definitions

NetworkSimplex.BALANCE_TOP_BOTTOM = 1
NetworkSimplex.BALANCE_LEFT_RIGHT = 2


function NetworkSimplex.new(graph, balancing)
  local simplex = {
    graph = graph,
    balancing = balancing,
  }
  setmetatable(simplex, NetworkSimplex)
  return simplex
end



function NetworkSimplex:run()

  assert (#self.graph.nodes > 0, "graph must contain at least one node")

  -- initialize the tree edge search index
  self.search_index = 1

  -- initialize internal edge parameters
  self.cut_value = {}
  for _,edge in ipairs(self.graph.edges) do
    self.cut_value[edge] = 0
  end

  -- reset graph information needed for ranking
  self.lim = {}
  self.low = {}
  self.parent_edge = {}
  self.ranking = Ranking.new()

  if #self.graph.nodes == 1 then
    self.ranking:setRank(self.graph.nodes[1], 1)
  else
    self:rankNodes()
  end
end



function NetworkSimplex:rankNodes()
  -- construct feasible tree of tight edges
  self:constructFeasibleTree()

  -- iteratively replace edges with negative cut values
  -- with non-tree edges (chosen by minimum slack)
  local leave_edge = self:findNegativeCutEdge()
  while leave_edge do
    local enter_edge = self:findReplacementEdge(leave_edge)

    assert(enter_edge, 'no non-tree edge to replace ' .. tostring(leave_edge) .. ' could be found')

    -- exchange leave_edge and enter_edge in the tree, updating
    -- the ranks and cut values of all nodes
    self:exchangeTreeEdges(leave_edge, enter_edge)

    -- find the next tree edge with a negative cut value, if
    -- there are any left
    leave_edge = self:findNegativeCutEdge()
  end

  if self.balancing == NetworkSimplex.BALANCE_TOP_BOTTOM then
    -- normalize by setting the least rank to zero
    self.ranking:normalizeRanks()

    -- move nodes to feasible ranks with the least number of nodes
    -- in order to avoid crowding and to improve the overall aspect
    -- ratio of the drawing
    self:balanceRanksTopBottom()
  elseif self.balancing == NetworkSimplex.BALANCE_LEFT_RIGHT then
    self:balanceRanksLeftRight()
  end
end



function NetworkSimplex:constructFeasibleTree()

  self:computeInitialRanking()

  -- find a maximal tree of tight edges in the graph
  while self:findTightTree() < #self.graph.nodes do

    local min_slack_edge = nil

    for _,node in ipairs(self.graph.nodes) do
      local out_edges = node:getOutgoingEdges()
      for _,edge in ipairs(out_edges) do
        if not self.tree_edge[edge] and self:isIncidentToTree(edge) then
          if not min_slack_edge or self:edgeSlack(edge) < self:edgeSlack(min_slack_edge) then
            min_slack_edge = edge
          end
        end
      end
    end

    if min_slack_edge then
      local delta = self:edgeSlack(min_slack_edge)

      if delta > 0 then
        local head = min_slack_edge:getHead()
        local tail = min_slack_edge:getTail()

        if self.tree_node[head] then
          delta = -delta
        end


        for _,node in ipairs(self.tree.nodes) do
          local rank = self.ranking:getRank(self.orig_node[node])
          self.ranking:setRank(self.orig_node[node], rank + delta)
        end
      end
    end
  end

  self:initializeCutValues()
end



function NetworkSimplex:findNegativeCutEdge()
  local minimum_edge = nil

  for n=1,#self.tree.edges do
    local index = self:nextSearchIndex()

    local edge = self.tree.edges[index]

    if self.cut_value[edge] < 0 then
      if minimum_edge then
        if self.cut_value[minimum_edge] > self.cut_value[edge] then
          minimum_edge = edge
        end
      else
        minimum_edge = edge
      end
    end
  end

  return minimum_edge
end



function NetworkSimplex:findReplacementEdge(leave_edge)
  local tail = leave_edge:getTail()
  local head = leave_edge:getHead()

  local v = nil
  local direction = nil

  if self.lim[tail] < self.lim[head] then
    v = tail
    direction = 'in'
  else
    v = head
    direction = 'out'
  end

  local search_root = v
  local enter_edge = nil
  local slack = math.huge

  -- TODO Jannis: Get rid of this recursion:

  local function find_edge(v, direction)

    if direction == 'out' then
      local out_edges = self.orig_node[v]:getOutgoingEdges()
      for _,edge in ipairs(out_edges) do
        local head = edge:getHead()
        local tree_head = self.tree_node[head]

        assert(head and tree_head)

        if not self.tree_edge[edge] then
          if not self:inTailComponentOf(tree_head, search_root) then
            if self:edgeSlack(edge) < slack or not enter_edge then
              enter_edge = edge
              slack = self:edgeSlack(edge)
            end
          end
        else
          if self.lim[tree_head] < self.lim[v] then
            find_edge(tree_head, 'out')
          end
        end
      end

      for _,edge in ipairs(v:getIncomingEdges()) do
        if slack <= 0 then
          break
        end

        local tail = edge:getTail()

        if self.lim[tail] < self.lim[v] then
          find_edge(tail, 'out')
        end
      end
    else
      local in_edges = self.orig_node[v]:getIncomingEdges()
      for _,edge in ipairs(in_edges) do
        local tail = edge:getTail()
        local tree_tail = self.tree_node[tail]

        assert(tail and tree_tail)

        if not self.tree_edge[edge] then
          if not self:inTailComponentOf(tree_tail, search_root) then
            if self:edgeSlack(edge) < slack or not enter_edge then
              enter_edge = edge
              slack = self:edgeSlack(edge)
            end
          end
        else
          if self.lim[tree_tail] < self.lim[v] then
            find_edge(tree_tail, 'in')
          end
        end
      end

      for _,edge in ipairs(v:getOutgoingEdges()) do
        if slack <= 0 then
          break
        end

        local head = edge:getHead()

        if self.lim[head] < self.lim[v] then
          find_edge(head, 'in')
        end
      end
    end
  end

  find_edge(v, direction)

  return enter_edge
end



function NetworkSimplex:exchangeTreeEdges(leave_edge, enter_edge)

  self:rerankBeforeReplacingEdge(leave_edge, enter_edge)

  local cutval = self.cut_value[leave_edge]
  local head = self.tree_node[enter_edge:getHead()]
  local tail = self.tree_node[enter_edge:getTail()]

  local ancestor = self:updateCutValuesUpToCommonAncestor(tail, head, cutval, true)
  local other_ancestor = self:updateCutValuesUpToCommonAncestor(head, tail, cutval, false)

  assert(ancestor == other_ancestor)

  -- remove the old edge from the tree
  self:removeEdgeFromTree(leave_edge)

  -- add the new edge to the tree
  local tree_edge = self:addEdgeToTree(enter_edge)

  -- set its cut value
  self.cut_value[tree_edge] = -cutval

  -- update DFS search tree traversal information
  self:calculateDFSRange(ancestor, self.parent_edge[ancestor], self.low[ancestor])
end



function NetworkSimplex:balanceRanksTopBottom()

  -- available ranks
  local ranks = self.ranking:getRanks()

  -- node to in/out weight mappings
  local in_weight = {}
  local out_weight = {}

  -- node to lowest/highest possible rank mapping
  local min_rank = {}
  local max_rank = {}

  -- compute the in and out weights of each node
  for _,node in ipairs(self.graph.nodes) do
    -- assume there are no restrictions on how to rank the node
    min_rank[node], max_rank[node] = ranks[1], ranks[#ranks]

    for _,edge in ipairs(node:getIncomingEdges()) do
      -- accumulate the weights of all incoming edges
      in_weight[node] = (in_weight[node] or 0) + edge.weight

      -- update the minimum allowed rank (which is the maximum of
      -- the ranks of all parent neighbors plus the minimum level
      -- separation caused by the connecting edges)
      local neighbour = edge:getNeighbour(node)
      local neighbour_rank = self.ranking:getRank(neighbour)
      min_rank[node] = math.max(min_rank[node], neighbour_rank + edge.minimum_levels)
    end

    for _,edge in ipairs(node:getOutgoingEdges()) do
      -- accumulate the weights of all outgoing edges
      out_weight[node] = (out_weight[node] or 0) + edge.weight

      -- update the maximum allowed rank (which is the minimum of
      -- the ranks of all child neighbors minus the minimum level
      -- separation caused by the connecting edges)
      local neighbour = edge:getNeighbour(node)
      local neighbour_rank = self.ranking:getRank(neighbour)
      max_rank[node] = math.min(max_rank[node], neighbour_rank - edge.minimum_levels)
    end

    -- check whether the in- and outweight is the same
    if in_weight[node] == out_weight[node] then

      -- check which of the allowed ranks has the least number of nodes
      local min_nodes_rank = min_rank[node]
      for n = min_rank[node] + 1, max_rank[node] do
        if #self.ranking:getNodes(n) < #self.ranking:getNodes(min_nodes_rank) then
          min_nodes_rank = n
        end
      end

      -- only move the node to the rank with the least number of nodes
      -- if it differs from the current rank of the node
      if min_nodes_rank ~= self.ranking:getRank(node) then
        self.ranking:setRank(node, min_nodes_rank)
      end

    end
  end
end



function NetworkSimplex:balanceRanksLeftRight()
  for _,edge in ipairs(self.tree.edges) do
    if self.cut_value[edge] == 0 then
      local other_edge = self:findReplacementEdge(edge)
      if other_edge then
        local delta = self:edgeSlack(other_edge)
        if delta > 1 then
          if self.lim[edge:getTail()] < self.lim[edge:getHead()] then
            self:rerank(edge:getTail(), delta / 2)
          else
            self:rerank(edge:getHead(), -delta / 2)
          end
        end
      end
    end
  end
end



function NetworkSimplex:computeInitialRanking()

  -- queue for nodes to rank next
  local queue = {}

  -- convenience functions for managing the queue
  local function enqueue(node) table.insert(queue, node) end
  local function dequeue() return table.remove(queue, 1) end

  -- reset the two-dimensional mapping from ranks to lists
  -- of corresponding nodes
  self.ranking:reset()

  -- mapping of nodes to the number of unscanned incoming edges
  local remaining_edges = {}

  -- add all sinks to the queue
  for _,node in ipairs(self.graph.nodes) do
    local edges = node:getIncomingEdges()

    remaining_edges[node] = #edges

    if #edges == 0 then
      enqueue(node)
    end
  end

  -- run long as there are nodes to be ranked
  while #queue > 0 do

    -- fetch the next unranked node from the queue
    local node = dequeue()

    -- get a list of its incoming edges
    local in_edges = node:getIncomingEdges()

    -- determine the minimum possible rank for the node
    local rank = 1
    for _,edge in ipairs(in_edges) do
      local neighbour = edge:getNeighbour(node)
      if self.ranking:getRank(neighbour) then
        -- the minimum possible rank is the maximum of all neighbor ranks plus
        -- the corresponding edge lengths
        rank = math.max(rank, self.ranking:getRank(neighbour) + edge.minimum_levels)
      end
    end

    -- rank the node
    self.ranking:setRank(node, rank)

    -- get a list of the node's outgoing edges
    local out_edges = node:getOutgoingEdges()

    -- queue neighbors of nodes for which all incoming edges have been scanned
    for _,edge in ipairs(out_edges) do
      local head = edge:getHead()
      remaining_edges[head] = remaining_edges[head] - 1
      if remaining_edges[head] <= 0 then
        enqueue(head)
      end
    end
  end
end



function NetworkSimplex:findTightTree()

  -- TODO: Jannis: Remove the recursion below:

  local marked = {}

  local function build_tight_tree(node)

    local out_edges = node:getOutgoingEdges()
    local in_edges = node:getIncomingEdges()

    local edges = lib.copy(out_edges)
    for _,v in ipairs(in_edges) do
      edges[#edges + 1] = v
    end

    for _,edge in ipairs(edges) do
      local neighbour = edge:getNeighbour(node)
      if (not marked[neighbour]) and math.abs(self:edgeSlack(edge)) < 0.00001 then
        self:addEdgeToTree(edge)

        for _,node in ipairs(edge.nodes) do
          marked[node] = true
        end

        if #self.tree.edges == #self.graph.nodes-1 then
          return true
        end

        if build_tight_tree(neighbour) then
          return true
        end
      end
    end

    return false
  end

  for _,node in ipairs(self.graph.nodes) do
    self.tree = Graph.new()
    self.tree_node = {}
    self.orig_node = {}
    self.tree_edge = {}
    self.orig_edge = {}

    build_tight_tree(node)

    if #self.tree.edges > 0 then
      break
    end
  end

  return #self.tree.nodes
end



function NetworkSimplex:edgeSlack(edge)
  -- make sure this is never called with a tree edge
  assert(not self.orig_edge[edge])

  local head_rank = self.ranking:getRank(edge:getHead())
  local tail_rank = self.ranking:getRank(edge:getTail())
  local length = head_rank - tail_rank
  return length - edge.minimum_levels
end



function NetworkSimplex:isIncidentToTree(edge)
  -- make sure this is never called with a tree edge
  assert(not self.orig_edge[edge])

  local head = edge:getHead()
  local tail = edge:getTail()

  if self.tree_node[head] and not self.tree_node[tail] then
    return true
  elseif self.tree_node[tail] and not self.tree_node[head] then
    return true
  else
    return false
  end
end



function NetworkSimplex:initializeCutValues()
  self:calculateDFSRange(self.tree.nodes[1], nil, 1)

  local function init(search)
    search:push({ node = self.tree.nodes[1], parent_edge = nil })
  end

  local function visit(search, data)
    search:setVisited(data, true)

    local into = data.node:getIncomingEdges()
    local out = data.node:getOutgoingEdges()

    for i=#into,1,-1 do
      local edge = into[i]
      if edge ~= data.parent_edge then
        search:push({ node = edge:getTail(), parent_edge = edge })
      end
    end

    for i=#out,1,-1 do
      local edge = out[i]
      if edge ~= data.parent_edge then
        search:push({ node = edge:getHead(), parent_edge = edge })
      end
    end
  end

  local function complete(search, data)
    if data.parent_edge then
      self:updateCutValue(data.parent_edge)
    end
  end

  DepthFirstSearch.new(init, visit, complete):run()
end



--- DFS algorithm that calculates post-order traversal indices and parent edges.
--
-- This algorithm performs a depth-first search in a directed or undirected
-- graph. For each node it calculates the node's post-order traversal index, the
-- minimum post-order traversal index of its descendants as well as the edge by
-- which the node was reached in the depth-first traversal.
--
function NetworkSimplex:calculateDFSRange(root, edge_from_parent, lowest)

  -- global traversal index counter
  local lim = lowest

  -- start the traversal at the root node
  local function init(search)
    search:push({ node = root, parent_edge = edge_from_parent, low = lowest })
  end

  -- visit nodes in depth-first order
  local function visit(search, data)
    -- mark node as visited so we only visit it once
    search:setVisited(data, true)

    -- remember the parent edge
    self.parent_edge[data.node] = data.parent_edge

    -- remember the minimum traversal index for this branch of the search tree
    self.low[data.node] = lim

    -- next we push all outgoing and incoming edges in reverse order
    -- to simulate recursive calls

    local into = data.node:getIncomingEdges()
    local out  = data.node:getOutgoingEdges()

    for i=#into,1,-1 do
      local edge = into[i]
      if edge ~= data.parent_edge then
        search:push({ node = edge:getTail(), parent_edge = edge })
      end
    end

    for i=#out,1,-1 do
      local edge = out[i]
      if edge ~= data.parent_edge then
        search:push({ node = edge:getHead(), parent_edge = edge })
      end
    end
  end

  -- when completing a node, store its own traversal index
  local function complete(search, data)
    self.lim[data.node] = lim
    lim = lim + 1
  end

  -- kick off the depth-first search
  DepthFirstSearch.new(init, visit, complete):run()

  local lim_lookup = {}
  local min_lim = math.huge
  local max_lim = -math.huge
  for _,node in ipairs(self.tree.nodes) do
    assert(self.lim[node])
    assert(self.low[node])
    assert(not lim_lookup[self.lim[node]])
    lim_lookup[self.lim[node]] = true
    min_lim = math.min(min_lim, self.lim[node])
    max_lim = math.max(max_lim, self.lim[node])
  end
  for n = min_lim, max_lim do
    assert(lim_lookup[n] == true)
  end
end



function NetworkSimplex:updateCutValue(tree_edge)

  local v = nil
  if self.parent_edge[tree_edge:getTail()] == tree_edge then
    v = tree_edge:getTail()
    dir = 1
  else
    v = tree_edge:getHead()
    dir = -1
  end

  local sum = 0

  local out_edges = self.orig_node[v]:getOutgoingEdges()
  local in_edges = self.orig_node[v]:getIncomingEdges()
  local edges = lib.copy(out_edges)
  for _,v in ipairs(in_edges) do
    edges[#edges + 1] = v
  end

  for _,edge in ipairs(edges) do
    local other = edge:getNeighbour(self.orig_node[v])

    local f = 0
    local rv = 0

    if not self:inTailComponentOf(self.tree_node[other], v) then
      f = 1
      rv = edge.weight
    else
      f = 0

      if self.tree_edge[edge] then
        rv = self.cut_value[self.tree_edge[edge]]
      else
        rv = 0
      end

      rv = rv - edge.weight
    end

    local d = 0

    if dir > 0 then
      if edge:isHead(self.orig_node[v]) then
        d = 1
      else
        d = -1
      end
    else
      if edge:isTail(self.orig_node[v]) then
        d = 1
      else
        d = -1
      end
    end

    if f > 0 then
      d = -d
    end

    if d < 0 then
      rv = -rv
    end

    sum = sum + rv
  end

  self.cut_value[tree_edge] = sum
end



function NetworkSimplex:inTailComponentOf(node, v)
  return (self.low[v] <= self.lim[node]) and (self.lim[node] <= self.lim[v])
end



function NetworkSimplex:nextSearchIndex()
  local index = 1

  -- avoid tree edge index out of bounds by resetting the search index
  -- as soon as it leaves the range of edge indices in the tree
  if self.search_index > #self.tree.edges then
    self.search_index = 1
    index = 1
  else
    index = self.search_index
    self.search_index = self.search_index + 1
  end

  return index
end



function NetworkSimplex:rerank(node, delta)
  local function init(search)
    search:push({ node = node, delta = delta })
  end

  local function visit(search, data)
    search:setVisited(data, true)

    local orig_node = self.orig_node[data.node]
    self.ranking:setRank(orig_node, self.ranking:getRank(orig_node) - data.delta)

    local into = data.node:getIncomingEdges()
    local out  = data.node:getOutgoingEdges()

    for i=#into,1,-1 do
      local edge = into[i]
      if edge ~= self.parent_edge[data.node] then
        search:push({ node = edge:getTail(), delta = data.delta })
      end
    end

    for i=#out,1,-1 do
      local edge = out[i]
      if edge ~= self.parent_edge[data.node] then
        search:push({ node = edge:getHead(), delta = data.delta })
      end
    end
  end

  DepthFirstSearch.new(init, visit):run()
end



function NetworkSimplex:rerankBeforeReplacingEdge(leave_edge, enter_edge)
  local delta = self:edgeSlack(enter_edge)

  if delta > 0 then
    local tail = leave_edge:getTail()

    if #tail.edges == 1 then
      self:rerank(tail, delta)
    else
      local head = leave_edge:getHead()

      if #head.edges == 1 then
        self:rerank(head, -delta)
      else
        if self.lim[tail] < self.lim[head] then
          self:rerank(tail, delta)
        else
          self:rerank(head, -delta)
        end
      end
    end
  end
end



function NetworkSimplex:updateCutValuesUpToCommonAncestor(v, w, cutval, dir)

  while not self:inTailComponentOf(w, v) do
    local edge = self.parent_edge[v]

    if edge:isTail(v) then
      d = dir
    else
      d = not dir
    end

    if d then
      self.cut_value[edge] = self.cut_value[edge] + cutval
    else
      self.cut_value[edge] = self.cut_value[edge] - cutval
    end

    if self.lim[edge:getTail()] > self.lim[edge:getHead()] then
      v = edge:getTail()
    else
      v = edge:getHead()
    end
  end

  return v
end



function NetworkSimplex:addEdgeToTree(edge)
  assert(not self.tree_edge[edge])

  -- create the new tree edge
  local tree_edge = edge:copy()
  self.orig_edge[tree_edge] = edge
  self.tree_edge[edge] = tree_edge

  -- create tree nodes if necessary
  for _,node in ipairs(edge.nodes) do
    local tree_node

    if self.tree_node[node] then
      tree_node = self.tree_node[node]
    else
      tree_node = node:copy()
      self.orig_node[tree_node] = node
      self.tree_node[node] = tree_node
    end

    self.tree:addNode(tree_node)
    tree_edge:addNode(tree_node)
  end

  self.tree:addEdge(tree_edge)

  return tree_edge
end



function NetworkSimplex:removeEdgeFromTree(edge)
  self.tree:deleteEdge(edge)
  self.tree_edge[self.orig_edge[edge]] = nil
  self.orig_edge[edge] = nil
end




-- Done

return NetworkSimplex