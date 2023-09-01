-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--- @release $Header$


local layered = {}

-- Namespace

require("pgf.gd").layered = layered


local lib = require "pgf.gd.lib"
local Storage = require "pgf.gd.lib.Storage"

--
-- This file defines some basic functions to compute and/or set the
-- ideal distances between nodes of any kind of layered drawing of a
-- graph.


---
-- Compute the ideal distance between two siblings
--
-- @param paddings A |Storage| object in which the computed distances
-- (paddings) are stored.
-- @param graph The graph object
-- @param n1 The first node
-- @param n2 The second node

function layered.ideal_sibling_distance (paddings, graph, n1, n2)
  local ideal_distance
  local sep

  local n1_is_node = n1.kind == "node"
  local n2_is_node = n2.kind == "node"

  if not n1_is_node and not n2_is_node then
    ideal_distance = graph.options['sibling distance']
    sep =   graph.options['sibling post sep']
          + graph.options['sibling pre sep']
  else
    if n1_is_node then
      ideal_distance = lib.lookup_option('sibling distance', n1, graph)
    else
      ideal_distance = lib.lookup_option('sibling distance', n2, graph)
    end
    sep =   (n1_is_node and lib.lookup_option('sibling post sep', n1, graph) or 0)
          + (n2_is_node and lib.lookup_option('sibling pre sep', n2, graph) or 0)
  end

  return math.max(ideal_distance, sep +
          ((n1_is_node and paddings[n1].sibling_post) or 0) -
                  ((n2_is_node and paddings[n2].sibling_pre) or 0))
end



---
-- Compute the baseline distance between two layers
--
-- The "baseline" distance is the distance between two layers that
-- corresponds to the distance of the two layers if the nodes where
-- "words" on two adjacent lines. In this case, the distance is
-- normally the layer_distance, but will be increased such that if we
-- draw a horizontal line below the deepest character on the first
-- line and a horizontal line above the highest character on the
-- second line, the lines will have a minimum distance of layer sep.
--
-- Since each node on the lines might have a different layer sep and
-- layer distance specified, the maximum over all the values is taken.
--
-- @param paddings A |Storage| object in which the distances
-- (paddings) are stored.
-- @param graph The graph in which the nodes reside
-- @param l1 An array of the nodes of the first layer
-- @param l2 An array of the nodes of the second layer

function layered.baseline_distance (paddings, graph, l1, l2)

  if #l1 == 0 or #l2 == 0 then
    return 0
  end

  local layer_distance = -math.huge
  local layer_pre_sep  = -math.huge
  local layer_post_sep = -math.huge

  local max_post = -math.huge
  local min_pre = math.huge

  for _,n in ipairs(l1) do
    layer_distance = math.max(layer_distance, lib.lookup_option('level distance', n, graph))
    layer_post_sep = math.max(layer_post_sep, lib.lookup_option('level post sep', n, graph))
    if n.kind == "node" then
      max_post = math.max(max_post, paddings[n].layer_post)
    end
  end

  for _,n in ipairs(l2) do
    layer_pre_sep = math.max(layer_pre_sep, lib.lookup_option('level pre sep', n, graph))
    if n.kind == "node" then
      min_pre = math.min(min_pre, paddings[n].layer_pre)
    end
  end

  return math.max(layer_distance, layer_post_sep + layer_pre_sep + max_post - min_pre)
end



---
-- Position nodes in layers using baselines
--
-- @param layers A |Storage| object assigning layers to vertices.
-- @param paddings A |Storage| object storing the computed distances
-- (paddings).
-- @param graph The graph in which the nodes reside

function layered.arrange_layers_by_baselines (layers, paddings, graph)

  local layer_vertices = Storage.newTableStorage()

  -- Decompose into layers:
  for _,v in ipairs(graph.vertices) do
    table.insert(layer_vertices[layers[v]], v)
  end

  if #layer_vertices > 0 then -- sanity check
    -- Now compute ideal distances and store
    local height = 0

    for _,v in ipairs(layer_vertices[1]) do
      v.pos.y = 0
    end

    for i=2,#layer_vertices do
      height = height + layered.baseline_distance(paddings, graph, layer_vertices[i-1], layer_vertices[i])

      for _,v in ipairs(layer_vertices[i]) do
        v.pos.y = height
      end
    end
  end
end




-- Done

return layered
