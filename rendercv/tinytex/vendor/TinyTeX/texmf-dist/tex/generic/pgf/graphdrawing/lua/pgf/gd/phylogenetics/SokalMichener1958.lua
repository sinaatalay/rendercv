-- Copyright 2013 by Sarah Mäusle and Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$




local SokalMichener1958 = {}


-- Namespace
require("pgf.gd.phylogenetics").SokalMichener1958 = SokalMichener1958

-- Imports
local InterfaceToAlgorithms = require("pgf.gd.interface.InterfaceToAlgorithms")
local DistanceMatrix        = require("pgf.gd.phylogenetics.DistanceMatrix")
local lib                   = require("pgf.gd.lib")
local Storage               = require("pgf.gd.lib.Storage")
local Digraph               = require("pgf.gd.model.Digraph")

-- Shorthand:
local declare = InterfaceToAlgorithms.declare


---
declare {
  key = "unweighted pair group method using arithmetic averages",
  algorithm = SokalMichener1958,
  phase = "phylogenetic tree generation",

  summary = [["
    The UPGMA (Unweighted Pair Group Method using arithmetic
    Averages) algorithm of Sokal and Michener, 1958. It generates a
    graph on the basis of such a distance matrix by generating nodes
    and computing the edge lengths.
  "]],
  documentation = [["
    This algorithm uses a distance matrix, ideally an ultrametric
    one, to compute the graph.
  "]],
  examples = [["
    \tikz \graph [phylogenetic tree layout, sibling distance=0pt, sibling sep=2pt,
                  unweighted pair group method using arithmetic averages,
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
  key = "upgma",
  use = { { key = "unweighted pair group method using arithmetic averages" } },
  summary = "An shorthand for |unweighted pair group method using arithmetic averages|"
}




--
-- The run function of the upgma algorithm.
--
-- You must setup the following fields: The |main_algorithm| must
-- store the main algorithm object (for phase |main|). The |distances|
-- field must be a |Storage| object that will get filled with the
-- distances computed by this algorithm. The |lengths| field must also
-- be a |Storage| for the computed distances.
--

function SokalMichener1958:run()
  self.distances = Storage.newTableStorage()

  self.tree = Digraph.new(self.main_algorithm.digraph)

  -- store the phylogenetic tree object, containing all user-specified
  -- graph information
  self:runUPGMA()
  self:createFinalEdges()

  return self.tree
end



-- UPGMA (Unweighted Pair Group Method using arithmetic Averages) algorithm
-- (Sokal and Michener, 1958)
--
--  this function generates a graph on the basis of such a distance
--  matrix by generating nodes and computing the edge lengths; the x-
--  and y-positions of the nodes must be set separately
--
--  requirement: a distance matrix, ideally an ultrametric
function SokalMichener1958:runUPGMA()
  local matrix = DistanceMatrix.graphDistanceMatrix(self.tree)

  local g = self.tree
  local clusters = {}

  -- create the clusters
  for _,v in ipairs(g.vertices) do
    clusters[#clusters+1] = self:newCluster(v)
  end

  -- Initialize the distances of these clusters:
  for _,cx in ipairs(clusters) do
    for _,cy in ipairs(clusters) do
      cx.distances[cy] = matrix[cx.root][cy.root]
    end
  end

  -- search for clusters with smallest distance and merge them
  while #clusters > 1 do
    local minimum_distance = math.huge
    local min_cluster1
    local min_cluster2
    for i, cluster in ipairs (clusters) do
      for j = i+1,#clusters do
        local cluster2 = clusters[j]
        local cluster_distance = self:getClusterDistance(cluster, cluster2)
        if cluster_distance < minimum_distance then
          minimum_distance, min_cluster1, min_cluster2 = cluster_distance, i, j
        end
      end
    end
    self:mergeClusters(clusters, min_cluster1, min_cluster2, minimum_distance)
  end
end


-- a new cluster is created
--
--  @param vertex The vertex the cluster is initialized with
--
--  @return The new cluster
function SokalMichener1958:newCluster(vertex)
  return {
    root = vertex, -- the root of the cluster
    size = 1, -- the number of vertices in the cluster,
    distances = {}, -- cached cluster distances to all other clusters
    cluster_height = 0 -- this value is equivalent to half the distance of the last two clusters
    -- that have been merged to form the current cluster;
    -- necessary for determining the distances of newly generated nodes to their children.
  }
end


-- gets the distance between two clusters
--
--  @param cluster1, cluster2 The two clusters
--
--  @return the distance between the clusters
function SokalMichener1958:getClusterDistance(c,d)
  return c.distances[d] or d.distances[c] or 0
end


-- merges two clusters by doing the following:
--  - deletes cluster2 from the clusters table
--  - adds all vertices from cluster2 to the vertices table of cluster1
--  - updates the distances of the new cluster to all remaining clusters
--  - generates a new node, as the new root of the cluster
--  - computes the distance of the new node to the former roots (for
--    later computation of the y-positions)
--  - generates edges, connecting the new node to the former roots
--  - updates the cluster height
--
-- @param clusters The array of clusters
-- @param index_of_first_cluster The index of the first cluster
-- @param index_of_second_cluster The index of the second cluster
-- @param distance The distance between the two clusters

function SokalMichener1958:mergeClusters(clusters, index_of_first_cluster, index_of_second_cluster, distance)

  local g = self.tree
  local cluster1 = clusters[index_of_first_cluster]
  local cluster2 = clusters[index_of_second_cluster]

  --update cluster distances
  for i,cluster in ipairs (clusters) do
    if cluster ~= cluster1 and cluster ~= cluster2 then
      local dist1 = self:getClusterDistance (cluster1, cluster)
      local dist2 = self:getClusterDistance (cluster2, cluster)
      local dist = (dist1*cluster1.size + dist2*cluster2.size)/ (cluster1.size+cluster2.size)
      cluster1.distances[cluster] = dist
      cluster.distances[cluster1] = dist
    end
  end

  -- delete cluster2
  table.remove(clusters, index_of_second_cluster)

  --add node and connect last vertex of each cluster with new node
  local new_node = InterfaceToAlgorithms.createVertex(
    self.main_algorithm,
    {
      name = "UPGMA-node ".. #self.tree.vertices+1,
      generated_options = { { key = "phylogenetic inner node" } },
    }
  )
  g:add{new_node}
  -- the distance of the new node ( = the new root of the cluster) to its children (= the former roots) is
  -- equivalent to half the distance between the two former clusters
  -- minus the respective cluster height
  local distance1 = distance/2-cluster1.cluster_height
  self.distances[new_node][cluster1.root] = distance1
  local distance2 = distance/2-cluster2.cluster_height
  self.distances[new_node][cluster2.root] = distance2

  -- these distances are also the final edge lengths, thus:
  self.lengths[new_node][cluster1.root] = distance1
  self.lengths[cluster1.root][new_node] = distance1

  self.lengths[new_node][cluster2.root] = distance2
  self.lengths[cluster2.root][new_node] = distance2

  g:connect(new_node, cluster1.root)
  g:connect(new_node, cluster2.root)

  cluster1.root = new_node
  cluster1.size = cluster1.size + cluster2.size
  cluster1.cluster_height = distance/2 -- set new height of the cluster
end



-- generates edges for the final graph
--
-- throughout the process of creating the tree, arcs have been
-- disconnected and connected, without truly creating edges. this is
-- done in this function
function SokalMichener1958:createFinalEdges()
  local g = self.tree
  local o_arcs = {} -- copy arcs since createEdge is going to modify the arcs array...
  for _,arc in ipairs(g.arcs) do
    o_arcs[#o_arcs+1] = arc
  end
  for _,arc in ipairs(o_arcs) do
    InterfaceToAlgorithms.createEdge(
      self.main_algorithm, arc.tail, arc.head,
      { generated_options = {
      { key = "phylogenetic edge", value = tostring(self.lengths[arc.tail][arc.head]) }
      }})
  end
end


return SokalMichener1958
