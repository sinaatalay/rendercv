-- Copyright 2012 by Till Tantau
-- Copyright 2015 by Malte Skambath
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information




local temporallayered = {}

-- Namespace

--require("pgf.gd").layered = layered
--require("pgf.gd.experimental.evolving").layered = layered

-- Import
local lib = require "pgf.gd.lib"
local Storage = require "pgf.gd.lib.Storage"
local layered = require "pgf.gd.layered"

--
-- This file defines some basic functions to compute and/or set the
-- ideal distances between nodes of any kind of layered drawing of a
-- graph.



---
-- Position nodes in layers using baselines
--
-- @param layers A |Storage| object assigning layers to vertices.
-- @param paddings A |Storage| object storing the computed distances
-- (paddings).
-- @param graph The graph in which the nodes reside
-- @param snapshots The list of snapshots over which the overlaying evolving
--                  graph exists
function temporallayered.arrange_layers_by_baselines (layers, paddings, graph, snapshots, vertex_snapshots)
  assert(vertex_snapshots, "vertex_snapshots must not be nil")
  --local layer_vertices = Storage.newTableStorage()
  local snapshots_layers = Storage.newTableStorage()
  local count_layers = 0
  -- Decompose into layers:
  for _,v in ipairs(graph.vertices) do
    local layer_vertices = snapshots_layers[vertex_snapshots[v]] or {}
    if layer_vertices[layers[v]] == nil then
      assert( layers[v], "layer of node " .. v.name .. " has not been computed.")
      layer_vertices[layers[v]] = {}
    end
    table.insert(layer_vertices[layers[v]], v)
    count_layers = math.max(count_layers, layers[v])
  end

  if count_layers > 0 then


    -- Now compute ideal distances and store
    local height = 0

    for _, s in ipairs(snapshots) do
      local layer_vertices = snapshots_layers[s]
      if #layer_vertices > 0 then -- sanity check
        for _,v in ipairs(layer_vertices[1]) do
          v.pos.y = 0
        end
      end
    end

    for i=2, count_layers do
      local distance = 0
      for _, s in ipairs(snapshots) do
        local layer_vertices = snapshots_layers[s]
        if #layer_vertices >= i then
          distance = math.max(
            distance,
            layered.baseline_distance(
              paddings,
              s,
              layer_vertices[i-1],
              layer_vertices[i]))
        end
      end

      height = height + distance

      for _, s in ipairs(snapshots) do
        local layer_vertices = snapshots_layers[s]
        if #layer_vertices >= i then
          for _,v in ipairs(layer_vertices[i]) do
            v.pos.y = height
          end
        end
      end
    end
  end
end




-- Done

return temporallayered
