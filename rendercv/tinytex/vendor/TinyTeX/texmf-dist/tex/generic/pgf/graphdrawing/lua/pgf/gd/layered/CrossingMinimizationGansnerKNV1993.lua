-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



local CrossingMinimizationGansnerKNV1993 = {}


-- Imports

local lib = require "pgf.gd.lib"
local DepthFirstSearch = require "pgf.gd.lib.DepthFirstSearch"



function CrossingMinimizationGansnerKNV1993:run()

  self:computeInitialRankOrdering()

  local best_ranking = self.ranking:copy()
  local best_crossings = self:countRankCrossings(best_ranking)

  for iteration=1,24 do
    local direction = (iteration % 2 == 0) and 'down' or 'up'

    self:orderByWeightedMedian(direction)
    self:transpose(direction)

    local current_crossings = self:countRankCrossings(self.ranking)

    if current_crossings < best_crossings then
      best_ranking = self.ranking:copy()
      best_crossings = current_crossings
    end
  end

  self.ranking = best_ranking:copy()

  return self.ranking
end



function CrossingMinimizationGansnerKNV1993:computeInitialRankOrdering()

  local best_ranking = self.ranking:copy()
  local best_crossings = self:countRankCrossings(best_ranking)

  for _,direction in ipairs({'down', 'up'}) do

    local function init(search)
      for i=#self.graph.nodes,1,-1 do
        local node = self.graph.nodes[i]
        if direction == 'down' then
          if node:getInDegree() == 0 then
            search:push(node)
            search:setDiscovered(node)
          end
        else
          if node:getOutDegree() == 0 then
            search:push(node)
            search:setDiscovered(node)
          end
        end
      end
    end

    local function visit(search, node)
      search:setVisited(node, true)

      local rank = self.ranking:getRank(node)
      local pos = self.ranking:getRankSize(rank)
      self.ranking:setRankPosition(node, pos)

      if direction == 'down' then
        local out = node:getOutgoingEdges()
        for i=#out,1,-1 do
          local neighbour = out[i]:getNeighbour(node)
          if not search:getDiscovered(neighbour) then
            search:push(neighbour)
            search:setDiscovered(neighbour)
          end
        end
      else
        local into = node:getIncomingEdges()
        for i=#into,1,-1 do
          local neighbour = into[i]:getNeighbour(node)
          if not search:getDiscovered(neighbour) then
            search:push(neighbour)
            search:setDiscovered(neighbour)
          end
        end
      end
    end

    DepthFirstSearch.new(init, visit):run()

    local crossings = self:countRankCrossings(self.ranking)

    if crossings < best_crossings then
      best_ranking = self.ranking:copy()
      best_crossings = crossings
    end
  end

  self.ranking = best_ranking:copy()

end



function CrossingMinimizationGansnerKNV1993:countRankCrossings(ranking)

  local crossings = 0

  local ranks = ranking:getRanks()

  for rank_index = 2, #ranks do
    local nodes = ranking:getNodes(ranks[rank_index])
    for i = 1, #nodes-1 do
      for j = i+1, #nodes do
        local v = nodes[i]
        local w = nodes[j]

        -- TODO Jannis: We are REQUIRED to only check edges that lead to nodes
        -- on the next or previous rank, depending on the sweep direction!!!!
        local cn_vw = self:countNodeCrossings(ranking, v, w, 'down')

        crossings = crossings + cn_vw
      end
    end
  end

  return crossings
end



function CrossingMinimizationGansnerKNV1993:countNodeCrossings(ranking, left_node, right_node, sweep_direction)

  local ranks = ranking:getRanks()
  local _, rank_index = lib.find(ranks, function (rank)
    return rank == ranking:getRank(left_node)
  end)
  local other_rank_index = (sweep_direction == 'down') and rank_index-1 or rank_index+1

  assert(ranking:getRank(left_node) == ranking:getRank(right_node))
  assert(rank_index >= 1 and rank_index <= #ranks)

  -- 0 crossings if we're at the top or bottom and are sweeping down or up
  if other_rank_index < 1 or other_rank_index > #ranks then
    return 0
  end

  local left_edges = {}
  local right_edges = {}

  if sweep_direction == 'down' then
    left_edges = left_node:getIncomingEdges()
    right_edges = right_node:getIncomingEdges()
  else
    left_edges = left_node:getOutgoingEdges()
    right_edges = right_node:getOutgoingEdges()
  end

  local crossings = 0

  local function left_neighbour_on_other_rank(edge)
    local neighbour = edge:getNeighbour(left_node)
    return ranking:getRank(neighbour) == ranking:getRanks()[other_rank_index]
  end

  local function right_neighbour_on_other_rank(edge)
    local neighbour = edge:getNeighbour(right_node)
    return ranking:getRank(neighbour) == ranking:getRanks()[other_rank_index]
  end

  for _,left_edge in ipairs(left_edges) do
    if left_neighbour_on_other_rank(left_edge) then
      local left_neighbour = left_edge:getNeighbour(left_node)

      for _,right_edge in ipairs(right_edges) do
        if right_neighbour_on_other_rank(right_edge) then
          local right_neighbour = right_edge:getNeighbour(right_node)

          local left_position = ranking:getRankPosition(left_neighbour)
          local right_position = ranking:getRankPosition(right_neighbour)

          local neighbour_diff = right_position - left_position

          if neighbour_diff < 0 then
            crossings = crossings + 1
          end
        end
      end
    end
  end

  return crossings
end



function CrossingMinimizationGansnerKNV1993:orderByWeightedMedian(direction)

  local median = {}

  local function get_index(n, node) return median[node] end
  local function is_fixed(n, node) return median[node] < 0 end

  if direction == 'down' then
    local ranks = self.ranking:getRanks()

    for rank_index = 2, #ranks do
      median = {}
      local nodes = self.ranking:getNodes(ranks[rank_index])
      for _,node in ipairs(nodes) do
        median[node] = self:computeMedianPosition(node, ranks[rank_index-1])
      end

      self.ranking:reorderRank(ranks[rank_index], get_index, is_fixed)
    end
  else
    local ranks = self.ranking:getRanks()

    for rank_index = 1, #ranks-1 do
      median = {}
      local nodes = self.ranking:getNodes(ranks[rank_index])
      for _,node in ipairs(nodes) do
        median[node] = self:computeMedianPosition(node, ranks[rank_index+1])
      end

      self.ranking:reorderRank(ranks[rank_index], get_index, is_fixed)
    end
  end
end



function CrossingMinimizationGansnerKNV1993:computeMedianPosition(node, prev_rank)

  local positions = lib.imap(
    node.edges,
    function (edge)
      local n = edge:getNeighbour(node)
      if self.ranking:getRank(n) == prev_rank then
        return self.ranking:getRankPosition(n)
      end
    end)

  table.sort(positions)

  local median = math.ceil(#positions / 2)
  local position = -1

  if #positions > 0 then
    if #positions % 2 == 1 then
      position = positions[median]
    elseif #positions == 2 then
      return (positions[1] + positions[2]) / 2
    else
      local left = positions[median-1] - positions[1]
      local right = positions[#positions] - positions[median]
      position = (positions[median-1] * right + positions[median] * left) / (left + right)
    end
  end

  return position
end



function CrossingMinimizationGansnerKNV1993:transpose(sweep_direction)

  local function transpose_rank(rank)

    local improved = false

    local nodes = self.ranking:getNodes(rank)

    for i = 1, #nodes-1 do
      local v = nodes[i]
      local w = nodes[i+1]

      local cn_vw = self:countNodeCrossings(self.ranking, v, w, sweep_direction)
      local cn_wv = self:countNodeCrossings(self.ranking, w, v, sweep_direction)

      if cn_vw > cn_wv then
        improved = true

        self:switchNodePositions(v, w)
      end
    end

    return improved
  end

  local ranks = self.ranking:getRanks()

  local improved = false
  repeat
    local improved = false

    if sweep_direction == 'down' then
      for rank_index = 1, #ranks-1 do
        improved = transpose_rank(ranks[rank_index]) or improved
      end
    else
      for rank_index = #ranks-1, 1, -1 do
        improved = transpose_rank(ranks[rank_index]) or improved
      end
    end
  until not improved
end



function CrossingMinimizationGansnerKNV1993:switchNodePositions(left_node, right_node)
  assert(self.ranking:getRank(left_node) == self.ranking:getRank(right_node))
  assert(self.ranking:getRankPosition(left_node) < self.ranking:getRankPosition(right_node))

  local left_position = self.ranking:getRankPosition(left_node)
  local right_position = self.ranking:getRankPosition(right_node)

  self.ranking:switchPositions(left_node, right_node)

  local nodes = self.ranking:getNodes(self.ranking:getRank(left_node))
end



-- done

return CrossingMinimizationGansnerKNV1993
