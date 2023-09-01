-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local NodeRankingGansnerKNV1993 = {}


-- Imports

local Edge           = require "pgf.gd.deprecated.Edge"
local Node           = require "pgf.gd.deprecated.Node"

local NetworkSimplex = require "pgf.gd.layered.NetworkSimplex"



function NodeRankingGansnerKNV1993:run()

  local simplex = NetworkSimplex.new(self.graph, NetworkSimplex.BALANCE_TOP_BOTTOM)
  simplex:run()
  self.ranking = simplex.ranking

  return simplex.ranking
end



function NodeRankingGansnerKNV1993:mergeClusters()

  self.cluster_nodes = {}
  self.cluster_node = {}
  self.cluster_edges = {}

  self.original_nodes = {}
  self.original_edges = {}

  for _,cluster in ipairs(self.graph.clusters) do

    local cluster_node = Node.new{
      name = 'cluster@' .. cluster.name,
    }
    table.insert(self.cluster_nodes, cluster_node)

    for _,node in ipairs(cluster.nodes) do
      self.cluster_node[node] = cluster_node
      table.insert(self.original_nodes, node)
    end

    self.graph:addNode(cluster_node)
  end

  for _,edge in ipairs(self.graph.edges) do
    local tail = edge:getTail()
    local head = edge:getHead()

    if self.cluster_node[tail] or self.cluster_node[head] then
      table.insert(self.original_edges, edge)

      local cluster_edge = Edge.new{
        direction = Edge.RIGHT,
        weight = edge.weight,
        minimum_levels = edge.minimum_levels,
      }
      table.insert(self.cluster_edges, cluster_edge)

      if self.cluster_node[tail] then
        cluster_edge:addNode(self.cluster_node[tail])
      else
        cluster_edge:addNode(tail)
      end

      if self.cluster_node[head] then
        cluster_edge:addNode(self.cluster_node[head])
      else
        cluster_edge:addNode(head)
      end

    end
  end

  for _,edge in ipairs(self.cluster_edges) do
    self.graph:addEdge(edge)
  end

  for _,edge in ipairs(self.original_edges) do
    self.graph:deleteEdge(edge)
  end

  for _,node in ipairs(self.original_nodes) do
    self.graph:deleteNode(node)
  end
end



function NodeRankingGansnerKNV1993:createClusterEdges()
  for n = 1, #self.cluster_nodes-1 do
    local first_cluster = self.cluster_nodes[n]
    local second_cluster = self.cluster_nodes[n+1]

    local edge = Edge.new{
      direction = Edge.RIGHT,
      weight = 1,
      minimum_levels = 1,
    }

    edge:addNode(first_cluster)
    edge:addNode(second_cluster)

    self.graph:addEdge(edge)

    table.insert(self.cluster_edges, edge)
  end
end



function NodeRankingGansnerKNV1993:removeClusterEdges()
end



function NodeRankingGansnerKNV1993:expandClusters()

  for _,node in ipairs(self.original_nodes) do
    assert(self.ranking:getRank(self.cluster_node[node]))
    self.ranking:setRank(node, self.ranking:getRank(self.cluster_node[node]))
    self.graph:addNode(node)
  end

  for _,edge in ipairs(self.original_edges) do
    for _,node in ipairs(edge.nodes) do
      node:addEdge(edge)
    end
    self.graph:addEdge(edge)
  end

  for _,node in ipairs(self.cluster_nodes) do
    self.ranking:setRank(node, nil)
    self.graph:deleteNode(node)
  end

  for _,edge in ipairs(self.cluster_edges) do
    self.graph:deleteEdge(edge)
  end
end


-- done

return NodeRankingGansnerKNV1993