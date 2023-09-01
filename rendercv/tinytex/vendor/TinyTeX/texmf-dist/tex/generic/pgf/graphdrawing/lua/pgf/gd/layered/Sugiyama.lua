-- Copyright 2011 by Jannis Pohlmann, 2012 by Till Tantau
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



---
-- @section subsection {The Modular Sugiyama Method}
--
-- @end

local Sugiyama = {}

-- Namespace
require("pgf.gd.layered").Sugiyama = Sugiyama

-- Imports
local layered = require "pgf.gd.layered"
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare

local Ranking     = require "pgf.gd.layered.Ranking"
local Simplifiers = require "pgf.gd.lib.Simplifiers"

-- Deprecated stuff. Need to get rid of it!
local Edge        = require "pgf.gd.deprecated.Edge"
local Node        = require "pgf.gd.deprecated.Node"

local Iterators   = require "pgf.gd.deprecated.Iterators"
local Vector      = require "pgf.gd.deprecated.Vector"



---

declare {
  key       = "layered layout",
  algorithm = Sugiyama,

  preconditions = {
    connected = true,
    loop_free = true,
  },

  postconditions = {
    upward_oriented = true
  },

  old_graph_model = true,

  summary = [["
    The |layered layout| is the key used to select the modular Sugiyama
    layout algorithm.
  "]],
  documentation = [["
    This algorithm consists of five consecutive steps, each of which can be
    configured independently of the other ones (how this is done is
    explained later in this section). Naturally, the ``best'' heuristics
    are selected by default, so there is typically no need to change the
    settings, but what is the ``best'' method for one graph need not be
    the best one for another graph.

    As can be seen in the first example, the algorithm will not only
    position the nodes of a graph, but will also perform an edge
    routing. This will look visually quite pleasing if you add the
    |rounded corners| option:
  "]],
  examples = {[["
    \tikz \graph [layered layout, sibling distance=7mm]
    {
      a -> {
        b,
        c -> { d, e, f }
      } ->
      h ->
      a
    };
  "]],[["
    \tikz [rounded corners] \graph [layered layout, sibling distance=7mm]
    {
      a -> {
        b,
        c -> { d, e, f }
      } ->
      h ->
      a
    };
  "]]
  }
}

---

declare {
  key = "minimum layers",
  type = "number",
  initial = "1",

  summary = [["
    The minimum number of levels that an edge must span. It is a bit of
    the opposite of the |weight| parameter: While a large |weight|
    causes an edge to become shorter, a larger |minimum layers| value
    causes an edge to be longer.
  "]],
  examples = [["
    \tikz \graph [layered layout] {
      a -- {b [> minimum layers=3], c, d} -- e -- a;
    };
  "]]
}


---

declare {
  key = "same layer",
  layer = 0,

  summary = [["
    The |same layer| collection allows you to enforce that several nodes
    a on the same layer of a layered layout (this option is also known
    as |same rank|). You use it like this:
  "]],
  examples = {[["
    \tikz \graph [layered layout] {
      a -- b -- c -- d -- e;

      { [same layer] a, b };
      { [same layer] d, e };
    };
  "]],[["
      \tikz [rounded corners] \graph [layered layout] {
        1972 -> 1976 -> 1978 -> 1980 -> 1982 -> 1984 -> 1986 -> 1988 -> 1990 -> future;

        { [same layer] 1972, Thompson };
        { [same layer] 1976, Mashey, Bourne },
        { [same layer] 1978, Formshell, csh },
        { [same layer] 1980, esh, vsh },
        { [same layer] 1982, ksh, "System-V" },
        { [same layer] 1984, v9sh, tcsh },
        { [same layer] 1986, "ksh-i" },
        { [same layer] 1988, KornShell ,Perl, rc },
        { [same layer] 1990, tcl, Bash },
        { [same layer] "future", POSIX, "ksh-POSIX" },

        Thompson -> { Mashey, Bourne, csh -> tcsh},
        Bourne -> { ksh, esh, vsh, "System-V", v9sh -> rc, Bash},
        { "ksh-i", KornShell } -> Bash,
        { esh, vsh, Formshell, csh } -> ksh,
        { KornShell, "System-V" } -> POSIX,
        ksh -> "ksh-i" -> KornShell -> "ksh-POSIX",
        Bourne -> Formshell,

        { [edge={draw=none}]
          Bash -> tcl,
          KornShell -> Perl
        }
      };
  "]]
  }
}



-- Implementation

function Sugiyama:run()
  if #self.graph.nodes <= 1 then
     return
  end

  local options = self.digraph.options

  local cycle_removal_algorithm_class         = options.algorithm_phases['cycle removal']
  local node_ranking_algorithm_class          = options.algorithm_phases['node ranking']
  local crossing_minimization_algorithm_class = options.algorithm_phases['crossing minimization']
  local node_positioning_algorithm_class      = options.algorithm_phases['node positioning']
  local edge_routing_algorithm_class          = options.algorithm_phases['layer edge routing']

  self:preprocess()

  -- Helper function for collapsing multiedges
  local function collapse (m,e)
    m.weight         = (m.weight or 0) + e.weight
    m.minimum_levels = math.max((m.minimum_levels or 0), e.minimum_levels)
  end

  -- Rank using cluster

  -- Create a subalgorithm object. Needed so that removed loops
  -- are not stored on top of removed loops from main call.
  local cluster_subalgorithm = { graph = self.graph }
  self.graph:registerAlgorithm(cluster_subalgorithm)

  self:mergeClusters()

  Simplifiers:removeLoopsOldModel(cluster_subalgorithm)
  Simplifiers:collapseMultiedgesOldModel(cluster_subalgorithm, collapse)

  cycle_removal_algorithm_class.new { main_algorithm = self, graph = self.graph }:run()
  self.ranking = node_ranking_algorithm_class.new{ main_algorithm = self, graph = self.graph }:run()
  self:restoreCycles()

  Simplifiers:expandMultiedgesOldModel(cluster_subalgorithm)
  Simplifiers:restoreLoopsOldModel(cluster_subalgorithm)

  self:expandClusters()

  -- Now do actual computation
  Simplifiers:collapseMultiedgesOldModel(cluster_subalgorithm, collapse)
  cycle_removal_algorithm_class.new{ main_algorithm = self, graph = self.graph }:run()
  self:insertDummyNodes()

  -- Main algorithm
  crossing_minimization_algorithm_class.new{
    main_algorithm = self,
    graph = self.graph,
    ranking = self.ranking
  }:run()
  node_positioning_algorithm_class.new{
    main_algorithm = self,
    graph = self.graph,
    ranking = self.ranking
  }:run()

  -- Cleanup
  self:removeDummyNodes()
  Simplifiers:expandMultiedgesOldModel(cluster_subalgorithm)
  edge_routing_algorithm_class.new{ main_algorithm = self, graph = self.graph }:run()
  self:restoreCycles()

end



function Sugiyama:preprocess()
  -- initialize edge parameters
  for _,edge in ipairs(self.graph.edges) do
    -- read edge parameters
    edge.weight = edge:getOption('weight')
    edge.minimum_levels = edge:getOption('minimum layers')

    -- validate edge parameters
    assert(edge.minimum_levels >= 0, 'the edge ' .. tostring(edge) .. ' needs to have a minimum layers value greater than or equal to 0')
  end
end



function Sugiyama:insertDummyNodes()
  -- enumerate dummy nodes using a globally unique numeric ID
  local dummy_id = 1

  -- keep track of the original edges removed
  self.original_edges = {}

  -- keep track of dummy nodes introduced
  self.dummy_nodes = {}

  for node in Iterators.topologicallySorted(self.graph) do
    local in_edges = node:getIncomingEdges()

    for _,edge in ipairs (in_edges) do
      local neighbour = edge:getNeighbour(node)
      local dist = self.ranking:getRank(node) - self.ranking:getRank(neighbour)

      if dist > 1 then
        local dummies = {}

        for i=1,dist-1 do
          local rank = self.ranking:getRank(neighbour) + i

          local dummy = Node.new{
            pos = Vector.new(),
            name = 'dummy@' .. neighbour.name .. '@to@' .. node.name .. '@at@' .. rank,
            kind = "dummy",
            orig_vertex = pgf.gd.model.Vertex.new{}
          }

          dummy_id = dummy_id + 1

          self.graph:addNode(dummy)
          self.ugraph:add {dummy.orig_vertex}

          self.ranking:setRank(dummy, rank)

          table.insert(self.dummy_nodes, dummy)
          table.insert(edge.bend_nodes, dummy)

          table.insert(dummies, dummy)
        end

        table.insert(dummies, 1, neighbour)
        table.insert(dummies, #dummies+1, node)

        for i = 2, #dummies do
          local source = dummies[i-1]
          local target = dummies[i]

          local dummy_edge = Edge.new{
            direction = Edge.RIGHT,
            reversed = false,
            weight = edge.weight, -- TODO or should we divide the weight of the original edge by the number of virtual edges?
          }

          dummy_edge:addNode(source)
          dummy_edge:addNode(target)

          self.graph:addEdge(dummy_edge)
        end

        table.insert(self.original_edges, edge)
      end
    end
  end

  for _,edge in ipairs(self.original_edges) do
    self.graph:deleteEdge(edge)
  end
end



function Sugiyama:removeDummyNodes()
  -- delete dummy nodes
  for _,node in ipairs(self.dummy_nodes) do
    self.graph:deleteNode(node)
  end

  -- add original edge again
  for _,edge in ipairs(self.original_edges) do
    -- add edge to the graph
    self.graph:addEdge(edge)

    -- add edge to the nodes
    for _,node in ipairs(edge.nodes) do
      node:addEdge(edge)
    end

    -- convert bend nodes to bend points for TikZ
    for _,bend_node in ipairs(edge.bend_nodes) do
      local point = bend_node.pos:copy()
      table.insert(edge.bend_points, point)
    end

    if edge.reversed then
      local bp = edge.bend_points
      for i=1,#bp/2 do
        local j = #bp + 1 - i
        bp[i], bp[j] = bp[j], bp[i]
      end
    end

    -- clear the list of bend nodes
    edge.bend_nodes = {}
  end
end



function Sugiyama:mergeClusters()

  self.cluster_nodes = {}
  self.cluster_node = {}
  self.cluster_edges = {}
  self.cluster_original_edges = {}
  self.original_nodes = {}

  for _,cluster in ipairs(self.graph.clusters) do

    local cluster_node = cluster.nodes[1]
    table.insert(self.cluster_nodes, cluster_node)

    for n = 2, #cluster.nodes do
      local other_node = cluster.nodes[n]
      self.cluster_node[other_node] = cluster_node
      table.insert(self.original_nodes, other_node)
    end
  end

  for _,edge in ipairs(self.graph.edges) do
    local tail = edge:getTail()
    local head = edge:getHead()

    if self.cluster_node[tail] or self.cluster_node[head] then
      local cluster_edge = Edge.new{
        direction = Edge.RIGHT,
        weight = edge.weight,
        minimum_levels = edge.minimum_levels,
      }

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

      table.insert(self.cluster_edges, cluster_edge)
      table.insert(self.cluster_original_edges, edge)
    end
  end

  for n = 1, #self.cluster_nodes-1 do
    local first_node = self.cluster_nodes[n]
    local second_node = self.cluster_nodes[n+1]

    local edge = Edge.new{
      direction = Edge.RIGHT,
      weight = 1,
      minimum_levels = 1,
    }

    edge:addNode(first_node)
    edge:addNode(second_node)

    table.insert(self.cluster_edges, edge)
  end

  for _,node in ipairs(self.original_nodes) do
    self.graph:deleteNode(node)
  end
  for _,edge in ipairs(self.cluster_edges) do
    self.graph:addEdge(edge)
  end
  for _,edge in ipairs(self.cluster_original_edges) do
    self.graph:deleteEdge(edge)
  end
end



function Sugiyama:expandClusters()

  for _,node in ipairs(self.original_nodes) do
    self.ranking:setRank(node, self.ranking:getRank(self.cluster_node[node]))
    self.graph:addNode(node)
  end

  for _,edge in ipairs(self.cluster_original_edges) do
    for _,node in ipairs(edge.nodes) do
      node:addEdge(edge)
    end
    self.graph:addEdge(edge)
  end

  for _,edge in ipairs(self.cluster_edges) do
    self.graph:deleteEdge(edge)
  end
end


function Sugiyama:restoreCycles()
  for _,edge in ipairs(self.graph.edges) do
    edge.reversed = false
  end
end





-- done

return Sugiyama
