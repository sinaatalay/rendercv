-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local NodeRankingMinimumHeight = {}

-- Imports

local Ranking = require "pgf.gd.layered.Ranking"
local Iterators = require "pgf.gd.deprecated.Iterators"


function NodeRankingMinimumHeight:run()
  local ranking = Ranking.new()

  for node in Iterators.topologicallySorted(self.graph) do
    local edges = node:getIncomingEdges()

    if #edges == 0 then
      ranking:setRank(node, 1)
    else
      local max_rank = -math.huge
      for _,edge in ipairs(edges) do
        max_rank = math.max(max_rank, ranking:getRank(edge:getNeighbour(node)))
      end

      assert(max_rank >= 1)

      ranking:setRank(node, max_rank + 1)
    end
  end

  return ranking
end


-- done

return NodeRankingMinimumHeight
