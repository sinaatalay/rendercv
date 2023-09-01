-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--- A class for creating and handling "coarse" versions of a graph. Such versions contain
-- less nodes and edges than the original graph while retaining the overall
-- structure. This class offers functions to create coarse graphs and to expand them
-- to regain their original size.

-- Imports
local Digraph = require "pgf.gd.model.Digraph"
local Vertex = require "pgf.gd.model.Vertex"
local Arc = require "pgf.gd.model.Arc"

local lib = require "pgf.gd.lib"

local CoarseGraph = Digraph.new()
CoarseGraph.__index = CoarseGraph

--- Creates a new coarse graph derived from an existing graph.
--
-- Generates a coarse graph for the input |Digraph|.
--
-- Coarsening describes the process of reducing the amount of vertices in a graph
-- by merging vertices into pseudo-vertices. There are different strategies,
-- to decide which vertices should be merged, like merging vertices that belong to edges in a
-- maximal independent edge set or by creating pseudo-vertices based on a maximal
-- independent node set. Those strategies are called
-- schemes.
--
-- Coarsening is not performed automatically. The function |CoarseGraph:coarsen|
-- can be used to further coarsen the graph, or the function |CoarseGraph:uncoarsen|
-- can be used to restore the previous state.
--
-- Note, however, that the input \meta{graph} is always modified in-place, so
-- if the original version of \meta{graph} is needed in parallel to its
-- coarse representations, a deep copy of \meta{graph} needs to be passed over
-- to |CoarseGraph.new|.
--
-- @param graph  An existing graph that needs to be coarsened.
-- @param fw_attributes The user defined attributes, possibly attached to vertices.

function CoarseGraph.new(ugraph, fw_attributes)
  local coarse_graph = {
    ugraph = ugraph,
    level = 0,
    scheme = CoarseGraph.coarsen_independent_edges,
    ratio = 0,
    fw_attributes = fw_attributes,
    collapsed_vertices = {}
  }
  setmetatable(coarse_graph, CoarseGraph)
  return coarse_graph
end

-- locals for performance
local find_maximal_matching, arc_function

-- This function performs one coarsening step: It finds all independent vertex
-- set according to |scheme|, coarsens them and adds the newly created
-- vertices to the collapsed_vertices table, associating them with the current
-- level.
function CoarseGraph:coarsen()
  -- update the level
  self.level = self.level + 1

  local vertices = self.ugraph.vertices
  local old_graph_size = #vertices
  local c = {}
  local fw_attributes = self.fw_attributes
  local ugraph = self.ugraph

  if self.scheme == CoarseGraph.coarsen_independent_edges then
    local matching = find_matching(ugraph)
    local collapse_vertex

    for _,arc in ipairs(matching) do
      -- get the two nodes of the edge that we are about to collapse
      local a_h = arc.head
      local a_t = arc.tail
      local collapse_vertices = {a_h, a_t}
      collapse_vertex = Vertex.new {weight = 0, mass = 0}

      ugraph:collapse(collapse_vertices,
                      collapse_vertex,
                      function (a,b)
                        a.weight = a.weight + b.weight
                        a.mass = a.mass + b.mass
                        if fw_attributes then
                          for key,value in pairs(fw_attributes[b]) do
                            if fw_attributes.functions[key] then
                              fw_attributes.functions[key](a,b)
                            elseif type(value) == "number" then
                              local tmp = fw_attributes[a]
                              if not tmp[key] then
                                tmp[key] = 0
                              end
                              tmp[key] = tmp[key] + value
                            end
                          end
                        end
                      end,
                      function (a,b)
                        if a.weight == nil then
                          a.weight = b.weight
                        else
                          a.weight = a.weight + b.weight
                        end
                      end)

      local c_v_p = collapse_vertex.pos
      local a_h_p = a_h.pos
      local a_t_p = a_t.pos
      c_v_p.x = (a_h_p.x + a_t_p.x)/2
      c_v_p.y = (a_h_p.y + a_t_p.y)/2

      c[#c+1] = collapse_vertex
      ugraph:remove{a_h, a_t}
    end

    -- Enter all collapsed vertices into a table to uncoarsen one level at a time
    self.collapsed_vertices[self.level] = c
  else
     assert(false, 'schemes other than CoarseGraph.coarsen_independent_edges are not implemented yet')
  end
  -- calculate the number of nodes ratio compared to the previous graph
  self.ratio = #vertices / old_graph_size
end

-- This function expands all vertices associated with the current level, then
-- updates the level.
function CoarseGraph:uncoarsen()
  local a = self.collapsed_vertices[self.level]
  local ugraph = self.ugraph
  local random = lib.random
  local randomseed = lib.randomseed

  for j=#a,1,-1 do
    randomseed(42)
    local to_expand = a[j]

    ugraph:expand(to_expand, function(a,b)
      b.pos.x = a.pos.x + random()*10
      b.pos.y = a.pos.y + random()*10
      end)
    ugraph:remove{to_expand}
    ugraph:sync()
  end

  self.level = self.level - 1
end

-- Getters
function CoarseGraph:getSize()
  return #self.ugraph.vertices
end


function CoarseGraph:getRatio()
  return self.ratio
end


function CoarseGraph:getLevel()
  return self.level
end


function CoarseGraph:getGraph()
  return self.ugraph
end

-- Private helper function to determine whether the second vertex in the
-- current arc has been matched already
--
-- @param arc The arc in question
-- @param vertex One of the arc's endpoints, either head or tail
-- @param matched_vertices The table holding all matched vertices
--
-- @return The arc if the other endpoint has not been matched yet
function arc_function (arc, vertex, matched_vertices)
  local x
  if arc.head ~= vertex then
    x = arc.head
  else
    x = arc.tail
  end
  if not matched_vertices[x] then
    return arc
  end
end

-- The function finding a maximum matching of independent arcs.
--
-- @param ugraph The current graph
--
-- @return A table of arcs which are in the matching
function find_matching(ugraph)
  local matching = {}
  local matched_vertices = {}
  local unmatched_vertices = {}
  local vertices = ugraph.vertices

  -- iterate over nodes in random order
  for _,j in ipairs(lib.random_permutation(#vertices)) do
    local vertex = vertices[j]
    -- ignore nodes that have already been matched
    if not matched_vertices[vertex] then
      local arcs = {}
      local all_arcs = {}
      for _,v in pairs(ugraph:incoming(vertex)) do all_arcs[#all_arcs+1] = v end
      for _,v in pairs(ugraph:outgoing(vertex)) do all_arcs[#all_arcs+1] = v end
      -- mark the node as matched
      matched_vertices[vertex] = true

      for _, a in ipairs(all_arcs) do
        arcs[#arcs +1] = arc_function(a, vertex, matched_vertices)
      end

      if #arcs > 0 then
        -- sort edges by the weights of the adjacent vertices
        table.sort(arcs, function (a, b)
          local x, y
          if a.head == vertex then
            x = a.tail
          else
            x = a.head
          end
          if b.head == vertex then
            y = b.tail
          else
            y = b.head
          end
          return x.weight < y.weight
        end)

        -- match the node against the neighbor with minimum weight
        matched_vertices[arcs[1].head] = true
        matched_vertices[arcs[1].tail] = true
        table.insert(matching, arcs[1])
      end
    end
  end

  -- generate a list of nodes that were not matched at all
  for _,j in ipairs(lib.random_permutation(#vertices)) do
    local vertex = vertices[j]
    if not matched_vertices[vertex] then
      table.insert(unmatched_vertices, vertex)
    end
  end
  return matching
end


-- done

return CoarseGraph
