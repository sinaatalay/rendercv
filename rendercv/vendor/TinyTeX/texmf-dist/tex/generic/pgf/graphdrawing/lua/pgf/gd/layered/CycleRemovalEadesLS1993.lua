-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



-- Declare
local CycleRemovalEadesLS1993 = {}

-- Import
local lib = require "pgf.gd.lib"


function CycleRemovalEadesLS1993:run()
  local copied_graph = self.graph:copy()

  local copied_node = {}
  local origin_node = {}
  local copied_edge = {}
  local origin_edge = {}

  local preserve = {}

  for _,edge in ipairs(self.graph.edges) do
    copied_edge[edge] = edge:copy()
    origin_edge[copied_edge[edge]] = edge

    for _,node in ipairs(edge.nodes) do
      if copied_node[node] then
        copied_edge[edge]:addNode(copied_node[node])
      else
        copied_node[node] = node:copy()
        origin_node[copied_node[node]] = node

        copied_graph:addNode(copied_node[node])
        copied_edge[edge]:addNode(copied_node[node])
      end
    end
  end

  local function node_is_sink(node)
    return node:getOutDegree() == 0
  end

  local function node_is_source(node)
    return node:getInDegree() == 0
  end

  local function node_is_isolated(node)
    return node:getDegree() == 0
  end

  while #copied_graph.nodes > 0 do
    local sink = lib.find(copied_graph.nodes, node_is_sink)
    while sink do
      for _,edge in ipairs(sink:getIncomingEdges()) do
        preserve[edge] = true
      end
      copied_graph:deleteNode(sink)
      sink = lib.find(copied_graph.nodes, node_is_sink)
    end

    local isolated_node = lib.find(copied_graph.nodes, node_is_isolated)
    while isolated_node do
      copied_graph:deleteNode(isolated_node)
      isolated_node = lib.find(copied_graph.nodes, node_is_isolated)
    end

    local source = lib.find(copied_graph.nodes, node_is_source)
    while source do
      for _,edge in ipairs(source:getOutgoingEdges()) do
        preserve[edge] = true
      end
      copied_graph:deleteNode(source)
      source = lib.find(copied_graph.nodes, node_is_source)
    end

    if #copied_graph.nodes > 0 then
      local max_node = nil
      local max_out_edges = nil
      local max_in_edges = nil

      for _,node in ipairs(copied_graph.nodes) do
        local out_edges = node:getOutgoingEdges()
        local in_edges = node:getIncomingEdges()

        if max_node == nil or (#out_edges - #in_edges > #max_out_edges - #max_in_edges) then
          max_node = node
          max_out_edges = out_edges
          max_in_edges = in_edges
        end
      end

      assert(max_node and max_out_edges and max_in_edges)

      for _,edge in ipairs(max_out_edges) do
        preserve[edge] = true
        copied_graph:deleteEdge(edge)
      end
      for _,edge in ipairs(max_in_edges) do
        copied_graph:deleteEdge(edge)
      end

      copied_graph:deleteNode(max_node)
    end
  end

  for _,edge in ipairs(self.graph.edges) do
    if not preserve[copied_edge[edge]] then
      edge.reversed = true
    end
  end
end

-- done

return CycleRemovalEadesLS1993