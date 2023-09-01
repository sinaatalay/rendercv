-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

local function full_print(g, pref)
  local s = ""

  for _,v in ipairs(g.vertices) do
    s = s .. tostring(v) .. "[" .. tostring(v.pos) .. "]\n "
  end

  s = s .. "\n"

  for _,a in ipairs(g.arcs) do
    for _,e in ipairs(a.syntactic_edges) do
      s = s .. tostring(e) .. "(" .. tostring(e.path) .. ")\n"
    end
  end

  pgf.debug((pref or "") .. s)
end


---
-- The |Sublayouts| module handles graphs for which multiple layouts are defined.
--
-- Please see Section~\ref{section-gd-sublayouts} for an overview of
-- sublayouts.
--

local Sublayouts = {}

-- Namespace
require("pgf.gd.control").Sublayouts = Sublayouts


-- Includes

local Digraph    = require "pgf.gd.model.Digraph"
local Vertex     = require "pgf.gd.model.Vertex"
local Coordinate = require "pgf.gd.model.Coordinate"
local Path       = require "pgf.gd.model.Path"

local lib        = require "pgf.gd.lib"

local InterfaceCore = require "pgf.gd.interface.InterfaceCore"

local Storage    = require "pgf.gd.lib.Storage"



-- Storages

local subs           = Storage.newTableStorage()
local already_nudged = Storage.new()
local positions      = Storage.newTableStorage()




-- Offset a node by an offset. This will \emph{also} offset all
-- subnodes, which arise from sublayouts.
--
-- @param vertex A vertex
-- @param pos A offset
--
local function offset_vertex(v, delta)
  v.pos:shiftByCoordinate(delta)
  for _,sub in ipairs(subs[v]) do
    offset_vertex(sub, delta)
  end
end


-- Nudge positioning. You can call this function  several times on the
-- same graph; nudging will be done only once.
--
-- @param graph A graph
--
local function nudge(graph)
  for _,v in ipairs(graph.vertices) do
    local nudge = v.options['nudge']
    if nudge and not already_nudged[v] then
      offset_vertex(v, nudge)
      already_nudged[v] = true
    end
  end
end



-- Create subgraph nodes
--
-- @param scope A scope
-- @param syntactic_digraph The syntactic digraph.
-- @param test Only for vertices whose subgraph collection passes this test will we create subgraph nodes
local function create_subgraph_node(scope, syntactic_digraph, vertex)

  local subgraph_collection = vertex.subgraph_collection
  local binding = InterfaceCore.binding

  local cloud = {}
  -- Add all points of n's collection, except for v itself, to the cloud:
  for _,v in ipairs(subgraph_collection.vertices) do
    if vertex ~= v then
      assert(syntactic_digraph:contains(v), "the layout must contain all nodes of the subgraph")
      for _,p in ipairs(v.path) do
        if type(p) == "table" then
          cloud[#cloud+1] = p + v.pos
        end
      end
    end
  end
  for _,e in ipairs(subgraph_collection.edges) do
    for _,p in ipairs(e.path) do
      if type(p) == "table" then
        cloud[#cloud+1] = p:clone()
      end
    end
  end
  local x_min, y_min, x_max, y_max, c_x, c_y = Coordinate.boundingBox(cloud)

  -- Shift the graph so that it is centered on the origin:
  for _,p in ipairs(cloud) do
    p:unshift(c_x,c_y)
  end

  local o = vertex.subgraph_info.generated_options

  o[#o+1] = { key = "subgraph point cloud", value = table.concat(lib.imap(cloud, tostring)) }
  o[#o+1] = { key = "subgraph bounding box height", value = tostring(y_max-y_min) .. "pt" }
  o[#o+1] = { key = "subgraph bounding box width", value = tostring(x_max-x_min) .. "pt" }

  -- And now, the "grand call":
  binding:createVertex(vertex.subgraph_info)

  -- Shift it were it belongs
  vertex.pos:shift(c_x,c_y)

  -- Remember all the subnodes for nudging and regardless
  -- positioning
  local s = {}
  for _,v in ipairs(subgraph_collection.vertices) do
    if v ~= vertex then
      s[#s+1] = v
    end
  end

  subs[vertex] = s
end


-- Tests whether two graphs have a vertex in common
local function intersection(g1, g2)
  for _,v in ipairs(g1.vertices) do
    if g2:contains(v) then
      return v
    end
  end
end

-- Tests whether a graph is a set is a subset of another
local function special_vertex_subset(vertices, graph)
  for _,v in ipairs(vertices) do
    if not graph:contains(v) and not (v.kind == "subgraph node") then
      return false
    end
  end
  return true
end



---
-- The layout recursion. See \ref{section-gd-sublayouts} for details.
--
-- @param scope The graph drawing scope
-- @param layout The to-be-laid-out collection
-- @param fun The to-be-called function for laying out the graph.
-- processed. This stack is important when a new syntactic vertex is
-- added by the algorithm: In this case, this vertex is added to all
-- layouts on this stack.
--
-- @return A laid out graph.

function Sublayouts.layoutRecursively(scope, layout, fun)

  -- Step 1: Iterate over all sublayouts of the current layout:
  local resulting_graphs = {}
  local loc = Storage.new()

  -- Now, iterate over all sublayouts
  for i,child in ipairs(layout:childrenOfKind(InterfaceCore.sublayout_kind)) do
    resulting_graphs[i] = Sublayouts.layoutRecursively(scope, child, fun)
    loc[resulting_graphs[i]] = child
  end

  -- Step 2: Run the merge process:
  local merged_graphs = {}

  while #resulting_graphs > 0 do

    local n = #resulting_graphs

    -- Setup marked array:
    local marked = {}
    for i=1,n do
      marked[i] = false
    end

    -- Mark first graph and copy everything from there
    marked[1] = true
    local touched = Storage.new()
    for _,v in ipairs(resulting_graphs[1].vertices) do
      v.pos = positions[v][resulting_graphs[1]]
      touched[v] = true
    end

    -- Repeatedly find a node that is connected to a marked node:
    local i = 1
    while i <= n do
      if not marked[i] then
        for j=1,n do
          if marked[j] then
            local v = intersection(resulting_graphs[i], resulting_graphs[j])
            if v then
              -- Aha, they intersect at vertex v

              -- Mark the i-th graph:
              marked[i] = true
              connected_some_graph = true

              -- Shift the i-th graph:
              local x_offset = v.pos.x - positions[v][resulting_graphs[i]].x
              local y_offset = v.pos.y - positions[v][resulting_graphs[i]].y

              for _,u in ipairs(resulting_graphs[i].vertices) do
                if not touched[u] then
                  touched[u] = true
                  u.pos = positions[u][resulting_graphs[i]]:clone()
                  u.pos:shift(x_offset, y_offset)

                  for _,a in ipairs(resulting_graphs[i]:outgoing(u)) do
                    for _,e in ipairs(a.syntactic_edges) do
                      for _,p in ipairs(e.path) do
                        if type(p) == "table" then
                          p:shift(x_offset, y_offset)
                        end
                      end
                    end
                  end
                end
              end

              -- Restart
              i = 0
              break
            end
          end
        end
      end
      i = i + 1
    end

    -- Now, we can collapse all marked graphs into one graph:
    local merge = Digraph.new {}
    merge.syntactic_digraph = merge
    local remaining = {}

    -- Add all vertices and edges:
    for i=1,n do
      if marked[i] then
        merge:add (resulting_graphs[i].vertices)
        for _,a in ipairs(resulting_graphs[i].arcs) do
          local ma = merge:connect(a.tail,a.head)
          for _,e in ipairs(a.syntactic_edges) do
            ma.syntactic_edges[#ma.syntactic_edges+1] = e
          end
        end
          else
        remaining[#remaining + 1] = resulting_graphs[i]
      end
    end

    -- Remember the first layout this came from:
    loc[merge] = loc[resulting_graphs[1]]

    -- Restart with rest:
    merged_graphs[#merged_graphs+1] = merge

    resulting_graphs = remaining
  end

  -- Step 3: Run the algorithm on the layout:

  local class = layout.options.algorithm_phases.main
  assert (type(class) == "table", "algorithm selection failed")

  local algorithm = class
  local uncollapsed_subgraph_nodes = lib.imap(
    scope.collections[InterfaceCore.subgraph_node_kind] or {},
    function (c)
      if c.parent_layout == layout then
        return c.subgraph_node
      end
    end)


  -- Create a new syntactic digraph:
  local syntactic_digraph = Digraph.new {
    options = layout.options
  }

  syntactic_digraph.syntactic_digraph = syntactic_digraph

  -- Copy all vertices and edges from the collection...
  syntactic_digraph:add (layout.vertices)
  for _,e in ipairs(layout.edges) do
    syntactic_digraph:add {e.head, e.tail}
    local arc = syntactic_digraph:connect(e.tail, e.head)
    arc.syntactic_edges[#arc.syntactic_edges+1] = e
  end

  -- Find out which subgraph nodes can be created now and make them part of the merged graphs
  for i=#uncollapsed_subgraph_nodes,1,-1 do
    local v = uncollapsed_subgraph_nodes[i]
    local vertices = v.subgraph_collection.vertices
    -- Test, if all vertices of the subgraph are in one of the merged graphs.
    for _,g in ipairs(merged_graphs) do
      if special_vertex_subset(vertices, g) then
        -- Ok, we can create a subgraph now
        create_subgraph_node(scope, syntactic_digraph, v)
        -- Make it part of the collapse!
        g:add{v}
        -- Do not consider again
        uncollapsed_subgraph_nodes[i] = false
        break
      end
    end
  end

  -- Collapse the nodes that are part of a merged_graph
  local collapsed_vertices = {}
  for _,g in ipairs(merged_graphs) do

    local intersection = {}
    for _,v in ipairs(g.vertices) do
      if syntactic_digraph:contains(v) then
        intersection[#intersection+1] = v
      end
    end
    if #intersection > 0 then
      -- Compute bounding box of g (this should actually be the convex
      -- hull) Hmm...:
      local array = {}
      for _,v in ipairs(g.vertices) do
        local min_x, min_y, max_x, max_y = v:boundingBox()
        array[#array+1] = Coordinate.new(min_x + v.pos.x, min_y + v.pos.y)
        array[#array+1] = Coordinate.new(max_x + v.pos.x, max_y + v.pos.y)
      end
      for _,a in ipairs(g.arcs) do
        for _,e in ipairs(a.syntactic_edges) do
          for _,p in ipairs(e.path) do
            if type(p) == "table" then
              array[#array+1] = p
            end
          end
        end
      end
      local x_min, y_min, x_max, y_max, c_x, c_y = Coordinate.boundingBox(array)

      -- Shift the graph so that it is centered on the origin:
      for _,v in ipairs(g.vertices) do
        v.pos:unshift(c_x,c_y)
      end
      for _,a in ipairs(g.arcs) do
        for _,e in ipairs(a.syntactic_edges) do
          for _,p in ipairs(e.path) do
            if type(p) == "table" then
              p:unshift(c_x,c_y)
            end
          end
        end
      end

      x_min = x_min - c_x
      x_max = x_max - c_x
      y_min = y_min - c_y
      y_max = y_max - c_y

      local index = loc[g].event.index

      local v = Vertex.new {
        -- Standard stuff
        shape = "none",
        kind  = "node",
        path  = Path.new {
          "moveto",
          x_min, y_min,
          x_min, y_max,
          x_max, y_max,
          x_max, y_min,
          "closepath"
        },
        options = {},
        event = scope.events[index]
      }

      -- Update node_event
      scope.events[index].parameters = v

      local collapse_vertex = syntactic_digraph:collapse(
        intersection,
        v,
        nil,
        function (new_arc, arc)
          for _,e in ipairs(arc.syntactic_edges) do
            new_arc.syntactic_edges[#new_arc.syntactic_edges+1] = e
          end
        end)

      syntactic_digraph:remove(intersection)
      collapsed_vertices[#collapsed_vertices+1] = collapse_vertex
    end
  end

  -- Sort the vertices
  table.sort(syntactic_digraph.vertices, function(u,v) return u.event.index < v.event.index end)

  -- Should we "hide" the subgraph nodes?
  local hidden_node
  if not algorithm.include_subgraph_nodes then
    local subgraph_nodes = lib.imap (syntactic_digraph.vertices,
      function (v) if v.kind == "subgraph node" then return v end end)

    if #subgraph_nodes > 0 then
      hidden_node = Vertex.new {}
      syntactic_digraph:collapse(subgraph_nodes, hidden_node)
      syntactic_digraph:remove (subgraph_nodes)
      syntactic_digraph:remove {hidden_node}
    end
  end

  -- Now, we want to call the actual algorithm. This call may modify
  -- the layout's vertices and edges fields, namely when new vertices
  -- and edges are created. We then need to add these to our local
  -- syntactic digraph. So, we remember the length of these fields
  -- prior to the call and then add everything ``behind'' these
  -- positions later on.

  -- Ok, everything setup! Run the algorithm...
  fun(scope, algorithm, syntactic_digraph, layout)

  if hidden_node then
    syntactic_digraph:expand(hidden_node)
  end

  -- Now, we need to expand the collapsed vertices once more:
  for i=#collapsed_vertices,1,-1 do
    syntactic_digraph:expand(
      collapsed_vertices[i],
      function (c, v)
        v.pos:shiftByCoordinate(c.pos)
      end,
      function (a, v)
        for _,e in ipairs(a.syntactic_edges) do
          for _,p in ipairs(e.path) do
            if type(p) == "table" then
              p:shiftByCoordinate(v.pos)
            end
          end
        end
      end
    )
    for _,a in ipairs(syntactic_digraph:outgoing(collapsed_vertices[i])) do
      for _,e in ipairs(a.syntactic_edges) do
        for _,p in ipairs(e.path) do
          if type(p) == "table" then
            p:shiftByCoordinate(a.tail.pos)
            p:unshiftByCoordinate(e.tail.pos)
          end
        end
      end
    end
  end
  syntactic_digraph:remove(collapsed_vertices)

  -- Step 4: Create the layout node if necessary
  for i=#uncollapsed_subgraph_nodes,1,-1 do
    if uncollapsed_subgraph_nodes[i] then
      create_subgraph_node(scope, syntactic_digraph, uncollapsed_subgraph_nodes[i])
    end
  end

  -- Now seems like a good time to nudge and do regardless positioning
  nudge(syntactic_digraph)

  -- Step 5: Cleanup
  -- Push the computed position into the storage:
  for _,v in ipairs(syntactic_digraph.vertices) do
    positions[v][syntactic_digraph] = v.pos:clone()
  end

  return syntactic_digraph
end





---
-- Regardless positioning.
--
-- @param graph A graph
--
function Sublayouts.regardless(graph)
  for _,v in ipairs(graph.vertices) do
    local regardless = v.options['regardless at']
    if regardless then
      offset_vertex(v, regardless - v.pos)
    end
  end
end



-- Done

return Sublayouts
