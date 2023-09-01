-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



local NodePositioningGansnerKNV1993 = {}


-- Imports

local layered = require "pgf.gd.layered"

local Graph = require "pgf.gd.deprecated.Graph"
local Edge  = require "pgf.gd.deprecated.Edge"
local Node  = require "pgf.gd.deprecated.Node"

local NetworkSimplex = require "pgf.gd.layered.NetworkSimplex"
local Storage = require "pgf.gd.lib.Storage"


function NodePositioningGansnerKNV1993:run()
  local auxiliary_graph = self:constructAuxiliaryGraph()

  local simplex = NetworkSimplex.new(auxiliary_graph, NetworkSimplex.BALANCE_LEFT_RIGHT)
  simplex:run()
  local x_ranking = simplex.ranking

  local layers = Storage.new()

  local ranks = self.ranking:getRanks()
  for _,rank in ipairs(ranks) do
    local nodes = self.ranking:getNodes(rank)
    for _,node in ipairs(nodes) do
      node.pos.x = x_ranking:getRank(node.aux_node)
      layers[node.orig_vertex] = rank
    end
  end

  layered.arrange_layers_by_baselines(layers, self.main_algorithm.adjusted_bb, self.main_algorithm.ugraph)

  -- Copy back
  for _,rank in ipairs(ranks) do
    local nodes = self.ranking:getNodes(rank)
    for _,node in ipairs(nodes) do
      node.pos.y = node.orig_vertex.pos.y
    end
  end
end




function NodePositioningGansnerKNV1993:constructAuxiliaryGraph()

  local aux_graph = Graph.new()

  local edge_node = {}

  for _,node in ipairs(self.graph.nodes) do
    local copy = Node.new{
      name = node.name,
      orig_node = node,
    }
    node.aux_node = copy
    aux_graph:addNode(copy)
  end

  for i=#self.graph.edges,1,-1 do
    local edge = self.graph.edges[i]
    local node = Node.new{
      name = '{' .. tostring(edge) .. '}',
    }

    aux_graph:addNode(node)

    node.orig_edge = edge
    edge_node[edge] = node

    local head = edge:getHead()
    local tail = edge:getTail()

    local tail_edge = Edge.new{
      direction = Edge.RIGHT,
      minimum_levels = 0,
      weight = edge.weight * self:getOmega(edge),
    }
    tail_edge:addNode(node)
    tail_edge:addNode(tail.aux_node)
    aux_graph:addEdge(tail_edge)

    local head_edge = Edge.new{
      direction = Edge.RIGHT,
      minimum_levels = 0,
      weight = edge.weight * self:getOmega(edge),
    }
    head_edge:addNode(node)
    head_edge:addNode(head.aux_node)
    aux_graph:addEdge(head_edge)
  end

  local ranks = self.ranking:getRanks()
  for _,rank in ipairs(ranks) do
    local nodes = self.ranking:getNodes(rank)
    for n = 1, #nodes-1 do
      local v = nodes[n]
      local w = nodes[n+1]

      local separator_edge = Edge.new{
        direction = Edge.RIGHT,
        minimum_levels = self:getDesiredHorizontalDistance(v, w),
        weight = 0,
      }
      separator_edge:addNode(v.aux_node)
      separator_edge:addNode(w.aux_node)
      aux_graph:addEdge(separator_edge)
    end
  end

  return aux_graph
end



function NodePositioningGansnerKNV1993:getOmega(edge)
  local node1 = edge.nodes[1]
  local node2 = edge.nodes[2]

  if (node1.kind == "dummy") and (node2.kind == "dummy") then
    return 8
  elseif (node1.kind == "dummy") or (node2.kind == "dummy") then
    return 2
  else
    return 1
  end
end



function NodePositioningGansnerKNV1993:getDesiredHorizontalDistance(v, w)
  return layered.ideal_sibling_distance(self.main_algorithm.adjusted_bb, self.graph.orig_digraph, v.orig_vertex, w.orig_vertex)
end


-- done

return NodePositioningGansnerKNV1993