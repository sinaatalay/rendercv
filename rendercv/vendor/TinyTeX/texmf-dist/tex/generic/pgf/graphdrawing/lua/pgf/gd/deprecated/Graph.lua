-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
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




--- The Graph class
--
--

local Graph = {}
Graph.__index = Graph


-- Namespace

-- Imports
local Edge = require "pgf.gd.deprecated.Edge"

local lib = require "pgf.gd.lib"


--- Creates a new graph.
--
-- @param values  Values to override default graph settings.
--                The following parameters can be set:\par
--                |nodes|: The nodes of the graph.\par
--                |edges|: The edges of the graph.\par
--                |clusters|: The node clusters of the graph.\par
--                |options|: A table of node options passed over from \tikzname.
--                |events|: A sequence of events signaled during the graph specification.
--
-- @return A newly-allocated graph.
--
function Graph.new(values)
  local defaults = {
    nodes = {},
    edges = {},
    clusters = {},
    options = {},
    events = {},
  }
  setmetatable(defaults, Graph)
  if values then
    for k,v in pairs(values) do
      defaults[k] = v
    end
  end
  return defaults
end



--- Prepares a graph for an algorithm.
--
-- This method causes self, all its nodes, and all its edges to get
-- a new empty table for the key algorithm. This allows an algorithm to
-- store stuff with nodes and edges without them interfering with information
-- stored by other algorithms.
--
-- @param An algorithm object.

function Graph:registerAlgorithm(algorithm)
  self[algorithm] = self[algorithm] or {}

  -- Add an algorithm field to all nodes, all edges, and the graph:
  for _,n in pairs(self.nodes) do
    n[algorithm] = n[algorithm] or {}
  end
  for _,e in pairs(self.edges) do
    e[algorithm] = e[algorithm] or {}
  end
end


--- Sets the graph option \meta{name} to \meta{value}.
--
-- @param name Name of the option to be changed.
-- @param value New value for the graph option \meta{name}.
--
function Graph:setOption(name, value)
  self.options[name] = value
end



--- Returns the value of the graph option \meta{name}.
--
-- @param name Name of the option.
--
-- @return The value of the graph option \meta{name} or |nil|.
--
function Graph:getOption(name)
  return self.options[name]
end




--- Creates a shallow copy of a graph.
--
-- The nodes and edges of the original graph are not preserved in the copy.
--
-- @return A shallow copy of the graph.
--
function Graph:copy ()
   return Graph.new({options = self.options, events = self.events})
end


--- Adds a node to the graph.
--
-- @param node The node to be added.
--
function Graph:addNode(node)
   -- only add the node if it's not included in the graph yet
   if not self:findNode(node.name) then
      -- Does the node have an index, yet?
      if not node.index then
        node.index = #self.nodes + 1
      end

      table.insert(self.nodes, node)
   end
end



--- If possible, removes a node from the graph and returns it.
--
-- @param node The node to remove.
--
-- @return The removed node or |nil| if it was not found in the graph.
--
function Graph:removeNode(node)
  local _, index = lib.find(self.nodes, function (other)
    return other.name == node.name
  end)
  if index then
    table.remove(self.nodes, index)
    return node
  else
    return nil
  end
end



--- If possible, looks up the node with the given name in the graph.
--
-- @param name Name of the node to look up.
--
-- @return The node with the given name or |nil| if it was not found in the graph.
--
function Graph:findNode(name)
  return self:findNodeIf(function (node) return node.name == name end)
end



--- Looks up the first node for which the function \meta{test} returns |true|.
--
-- @param test A function that takes one parameter (a |Node|) and returns
--             |true| or |false|.
--
-- @return The first node for which \meta{test} returns |true|.
--
function Graph:findNodeIf(test)
  return lib.find(self.nodes, test)
end



--- Like removeNode, but also deletes all adjacent edges of the removed node.
--
-- This function also removes the deleted adjacent edges from all neighbors
-- of the removed node.
--
-- @param node The node to be deleted together with its adjacent edges.
--
-- @return The removed node or |nil| if the node was not found in the graph.
--
function Graph:deleteNode(node)
  local node = self:removeNode(node)
  if node then
    for _,edge in ipairs(node.edges) do
      self:removeEdge(edge)
      for _,other_node in ipairs(edge.nodes) do
        if other_node.name ~= node.name then
          other_node:removeEdge(edge)
        end
      end
    end
    node.edges = {}
  end
  return node
end



-- Checks whether the edge already exists in the graph and returns it if possible.
--
-- @param edge Edge to search for.
--
-- @return The edge if it was found in the graph, |nil| otherwise.
--
function Graph:findEdge(edge)
  return lib.find(self.edges, function (other) return other == edge end)
end



--- Adds an edge to the graph.
--
-- @param edge The edge to be added.
--
function Graph:addEdge(edge)
   if not edge.index then
      edge.index = #self.edges + 1
   end

   table.insert(self.edges, edge)
end



--- If possible, removes an edge from the graph and returns it.
--
-- @param edge The edge to be removed.
--
-- @return The removed edge or |nil| if it was not found in the graph.
--
function Graph:removeEdge(edge)
  local _, index = lib.find(self.edges, function (other) return other == edge end)
  if index then
    table.remove(self.edges, index)
    return edge
  else
    return nil
  end
end



--- Like removeEdge, but also removes the edge from its adjacent nodes.
--
-- @param edge The edge to be deleted.
--
-- @return The removed edge or |nil| if it was not found in the graph.
--
function Graph:deleteEdge(edge)
  local edge = self:removeEdge(edge)
  if edge then
    for _,node in ipairs(edge.nodes) do
      node:removeEdge(edge)
    end
  end
  return edge
end



--- Removes an edge between two nodes and also removes it from these nodes.
--
-- @param from Start node of the edge.
-- @param to   End node of the edge.
--
-- @return The deleted edge.
--
function Graph:deleteEdgeBetweenNodes(from, to)
  -- try to find the edge
  local edge = lib.find(self.edges, function (edge)
    return edge.nodes[1] == from and edge.nodes[2] == to
  end)

  -- delete and return the edge
  if edge then
    return self:deleteEdge(edge)
  else
    return nil
  end
end



--- Creates and adds a new edge to the graph.
--
-- @param first_node   The first node of the new edge.
-- @param second_node  The second node of the new edge.
-- @param direction    The direction of the new edge. Possible values are
--                     \begin{itemize}
--                     \item |Edge.UNDIRECTED|,
--                     \item |Edge.LEFT|,
--                     \item |Edge.RIGHT|,
--                     \item |Edge.BOTH| and
--                     \item |Edge.NONE| (for invisible edges).
--                     \end{itemize}
-- @param edge_nodes   A string of \tikzname\ edge nodes that needs to be passed
--                     back to the \TeX layer unmodified.
-- @param options      The options of the new edge.
-- @param tikz_options A table of \tikzname\ options to be used by graph drawing
--                     algorithms to treat the edge in special ways.
--
-- @return The newly created edge.
--
function Graph:createEdge(first_node, second_node, direction, edge_nodes, options, tikz_options)
  local edge = Edge.new{
    direction = direction,
    edge_nodes = edge_nodes,
    options = options,
    tikz_options = tikz_options
  }
  edge:addNode(first_node)
  edge:addNode(second_node)
  self:addEdge(edge)
  return edge
end



--- Returns the cluster with the given name or |nil| if no such cluster exists.
--
-- @param name Name of the node cluster to look up.
--
-- @return The cluster with the given name or |nil| if no such cluster is defined.
--
function Graph:findClusterByName(name)
  return lib.find(self.clusters, function (cluster)
    return cluster.name == name
  end)
end



--- Tries to add a cluster to the graph. Returns whether or not this was successful.
--
-- Clusters are supposed to have unique names. This function will add the given
-- cluster only if there is no cluster with this name already. It returns |true|
-- if the cluster was added and |false| otherwise.
--
-- @param cluster Cluster to add to the graph.
--
-- @return |true| if the cluster was added successfully, |false| otherwise.
--
function Graph:addCluster(cluster)
  if not self:findClusterByName(cluster.name) then
    table.insert(self.clusters, cluster)
  end
end





--- Returns a string representation of this graph including all nodes and edges.
--
-- @ignore This should not appear in the documentation.
--
-- @return Graph as string.
--
function Graph:__tostring()
  local tmp = Graph.__tostring
  Graph.__tostring = nil
  local result = "Graph<" .. tostring(self) .. ">(("
  Graph.__tostring = tmp

  local first = true
  for _,node in ipairs(self.nodes) do
    if first then first = false else result = result .. ", " end
    result = result .. tostring(node)
  end
  result = result .. "), ("
  first = true
  for _,edge in ipairs(self.edges) do
    if first then first = false else result = result .. ", " end
    result = result .. tostring(edge)
  end

  return result .. "))"
end



-- Done

return Graph
