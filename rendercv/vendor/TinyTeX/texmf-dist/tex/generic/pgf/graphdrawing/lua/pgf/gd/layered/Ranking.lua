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



--- The Ranking class is used by the Sugiyama algorithm to compute an
-- ordering on the nodes of a layer

local Ranking = {}
Ranking.__index = Ranking

-- Namespace
local layered = require "pgf.gd.layered"
layered.Ranking = Ranking


local lib = require "pgf.gd.lib"


-- TODO Jannis: document!


function Ranking.new()
  local ranking = {
    rank_to_nodes = {},
    node_to_rank = {},
    position_in_rank = {},
  }
  setmetatable(ranking, Ranking)
  return ranking
end



function Ranking:copy()
  local copied_ranking = Ranking.new()

  -- copy rank to nodes mapping
  for rank, nodes in pairs(self.rank_to_nodes) do
    copied_ranking.rank_to_nodes[rank] = lib.copy(self.rank_to_nodes[rank])
  end

  -- copy node to rank mapping
  copied_ranking.node_to_rank = lib.copy(self.node_to_rank)

  -- copy node to position in rank mapping
  copied_ranking.position_in_rank = lib.copy(self.position_in_rank)

  return copied_ranking
end



function Ranking:reset()
  self.rank_to_nodes = {}
  self.node_to_rank = {}
  self.position_in_rank = {}
end



function Ranking:getRanks()
  local ranks = {}
  for rank, nodes in pairs(self.rank_to_nodes) do
    table.insert(ranks, rank)
  end
  table.sort(ranks)
  return ranks
end



function Ranking:getRankSize(rank)
  if self.rank_to_nodes[rank] then
    return #self.rank_to_nodes[rank]
  else
    return 0
  end
end



function Ranking:getNodeInfo(node)
  return self:getRank(node), self:getRankPosition(node)
end



function Ranking:getNodes(rank)
  return self.rank_to_nodes[rank] or {}
end



function Ranking:getRank(node)
  return self.node_to_rank[node]
end



function Ranking:setRank(node, new_rank)
  local rank, pos = self:getNodeInfo(node)

  if rank == new_rank then
    return
  end

  if rank then
    for n = pos+1, #self.rank_to_nodes[rank] do
      local other_node = self.rank_to_nodes[rank][n]
      self.position_in_rank[other_node] = self.position_in_rank[other_node]-1
    end

    table.remove(self.rank_to_nodes[rank], pos)
    self.node_to_rank[node] = nil
    self.position_in_rank[node] = nil

    if #self.rank_to_nodes[rank] == 0 then
      self.rank_to_nodes[rank] = nil
    end
  end

  if new_rank then
    self.rank_to_nodes[new_rank] = self.rank_to_nodes[new_rank] or {}
    table.insert(self.rank_to_nodes[new_rank], node)
    self.node_to_rank[node] = new_rank
    self.position_in_rank[node] = #self.rank_to_nodes[new_rank]
  end
end



function Ranking:getRankPosition(node)
  return self.position_in_rank[node]
end



function Ranking:setRankPosition(node, new_pos)
  local rank, pos = self:getNodeInfo(node)

  assert((rank and pos) or ((not rank) and (not pos)))

  if pos == new_pos then
    return
  end

  if rank and pos then
    for n = pos+1, #self.rank_to_nodes[rank] do
      local other_node = self.rank_to_nodes[rank][n]
      self.position_in_rank[other_node] = self.position_in_rank[other_node]-1
    end

    table.remove(self.rank_to_nodes[rank], pos)
    self.node_to_rank[node] = nil
    self.position_in_rank[node] = nil
  end

  if new_pos then
    self.rank_to_nodes[rank] = self.rank_to_nodes[rank] or {}

    for n = new_pos+1, #self.rank_to_nodes[rank] do
      local other_node = self.rank_to_nodes[rank][new_pos]
      self.position_in_rank[other_node] = self.position_in_rank[other_node]+1
    end

    table.insert(self.rank_to_nodes[rank], node)
    self.node_to_rank[node] = rank
    self.position_in_rank[node] = new_pos
  end
end



function Ranking:normalizeRanks()

  -- get the current ranks
  local ranks = self:getRanks()

  local min_rank = ranks[1]
  local max_rank = ranks[#ranks]

  -- clear ranks
  self.rank_to_nodes = {}

  -- iterate over all nodes and rerank them manually
  for node in pairs(self.position_in_rank) do
    local rank, pos = self:getNodeInfo(node)
    local new_rank = rank - (min_rank - 1)

    self.rank_to_nodes[new_rank] = self.rank_to_nodes[new_rank] or {}
    self.rank_to_nodes[new_rank][pos] = node

    self.node_to_rank[node] = new_rank
  end
end



function Ranking:switchPositions(left_node, right_node)
  local left_rank = self.node_to_rank[left_node]
  local right_rank = self.node_to_rank[right_node]

  assert(left_rank == right_rank, 'only positions of nodes in the same rank can be switched')

  local left_pos = self.position_in_rank[left_node]
  local right_pos = self.position_in_rank[right_node]

  self.rank_to_nodes[left_rank][left_pos] = right_node
  self.rank_to_nodes[left_rank][right_pos] = left_node

  self.position_in_rank[left_node] = right_pos
  self.position_in_rank[right_node] = left_pos
end



function Ranking:reorderRank(rank, get_index_func, is_fixed_func)
  self:reorderTable(self.rank_to_nodes[rank], get_index_func, is_fixed_func)

  for n = 1, #self.rank_to_nodes[rank] do
    self.position_in_rank[self.rank_to_nodes[rank][n]] = n
  end
end



function Ranking:reorderTable(input, get_index_func, is_fixed_func)
  -- collect all allowed indices
  local allowed_indices = {}
  for n = 1, #input do
    if not is_fixed_func(n, input[n]) then
      table.insert(allowed_indices, n)
    end
  end

  -- collect all desired indices; for each of these desired indices,
  -- remember by which element it was requested
  local desired_to_real_indices = {}
  local sort_indices = {}
  for n = 1, #input do
    if not is_fixed_func(n, input[n]) then
      local index = get_index_func(n, input[n])
      if not desired_to_real_indices[index] then
        desired_to_real_indices[index] = {}
        table.insert(sort_indices, index)
      end
      table.insert(desired_to_real_indices[index], n)
    end
  end

  -- sort the desired indices
  table.sort(sort_indices)

  -- compute the final indices by counting the final indices generated
  -- prior to the current one and by mapping this number to the allowed
  -- index with the same number
  local final_indices = {}
  local n = 1
  for _,index in ipairs(sort_indices) do
    local real_indices = desired_to_real_indices[index]
    for _,real_index in ipairs(real_indices) do
      final_indices[real_index] = allowed_indices[n]
      n = n + 1
    end
  end

  -- flat-copy the input table so that we can still access the elements
  -- using their real index while overwriting the input table in-place
  local input_copy = lib.copy(input)

  -- move flexible elements to their final indices
  for old_index, new_index in pairs(final_indices) do
    input[new_index] = input_copy[old_index]
  end
end



-- Done

return Ranking