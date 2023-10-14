-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


---
-- This class controls the running of graph drawing algorithms on
-- graphs. In particular, it performs pre- and posttransformations and
-- also invokes the collapsing of sublayouts.
--
-- You do not call any of the methods of this class directly, the
-- whole class is included only for documentation purposes.
--
-- Before an algorithm is applied, a number of transformations will
-- have been applied, depending on the algorithm's |preconditions|
-- field:
-- %
-- \begin{itemize}
--   \item |connected|
--
--     If this property is set for an algorithm (that is, in the
--     |declare| statement for the algorithm the |predconditions| field
--     has the entry |connected=true| set), then the graph will be
--     decomposed into connected components. The algorithm is run on each
--     component individually.
--   \item |tree|
--
--     When set, the field |spanning_tree| of the algorithm will be set
--     to a spanning tree of the graph. This option implies |connected|.
--   \item |loop_free|
--
--     When set, all loops (arcs from a vertex to itself) will have been
--     removed when the algorithm runs.
--
--   \item |at_least_two_nodes|
--
--     When explicitly set to |false| (this precondition is |true| by
--     default), the algorithm will even be run if there is only a
--     single vertex in the graph.
-- \end{itemize}
--
-- Once the algorithm has run, the algorithm's |postconditions| will
-- be processed:
-- %
-- \begin{itemize}
--   \item |upward_oriented|
--
--     When set, the algorithm tells the layout pipeline that the graph
--     has been laid out in a layered manner with each layer going from
--     left to right and layers at a whole going upwards (positive
--     $y$-coordinates). The graph will then be rotated and possibly
--     swapped in accordance with the |grow| key set by the user.
--   \item |fixed|
--
--     When set, no rotational postprocessing will be done after the
--     algorithm has run. Usually, a graph is rotated to meet a user's
--     |orient| settings. However, when the algorithm has already
--     ``ideally'' rotated the graph, set this postcondition.
-- \end{itemize}
--
--
-- In addition to the above-described always-present and automatic
-- transformations, users may also specify additional pre- and
-- posttransformations. This happens when users install additional
-- algorithms in appropriate phases. In detail, the following happens
-- in order:
-- %
-- \begin{enumerate}
--   \item If specified, the graph is decomposed into connected
--     components and the following steps are applied to each component
--     individually.
--   \item All algorithms in the phase stack for the phase
--     |preprocessing| are applied to the component. These algorithms are
--     run one after the other in the order they appear in the phase stack.
--   \item If necessary, the spanning tree is now computed and
--     rotational information is gathered.
--   \item The single algorithm in phase |main| is called.
--   \item All algorithms in the phase stack for the phase 
--     |edge routing| are run.
--   \item All algorithms in the phase stack for phase |postprocessing|
--     are run.
--   \item Edge syncing, orientation, and anchoring are applied.
-- \end{enumerate}
--
-- If sublayouts are used, all of the above (except for anchoring)
-- happens for each sublayout.

local LayoutPipeline = {}


-- Namespace
require("pgf.gd.control").LayoutPipeline = LayoutPipeline


-- Imports
local Direct        = require "pgf.gd.lib.Direct"
local Storage       = require "pgf.gd.lib.Storage"
local Simplifiers   = require "pgf.gd.lib.Simplifiers"
local LookupTable   = require "pgf.gd.lib.LookupTable"
local Transform     = require "pgf.gd.lib.Transform"

local Arc           = require "pgf.gd.model.Arc"
local Vertex        = require "pgf.gd.model.Vertex"
local Digraph       = require "pgf.gd.model.Digraph"
local Coordinate    = require "pgf.gd.model.Coordinate"
local Path          = require "pgf.gd.model.Path"

local Sublayouts    = require "pgf.gd.control.Sublayouts"

local lib           = require "pgf.gd.lib"

local InterfaceCore = require "pgf.gd.interface.InterfaceCore"




-- Forward definitions

local prepare_events



-- The main ``graph drawing pipeline'' that handles the pre- and
-- postprocessing for a graph. This method is called by the display
-- interface.
--
-- @param scope A graph drawing scope.

function LayoutPipeline.run(scope)

  -- The pipeline...

  -- Step 1: Preparations

  -- Prepare events
  prepare_events(scope.events)

  -- Step 2: Recursively layout the graph, starting with the root layout
  local root_layout = assert(scope.collections[InterfaceCore.sublayout_kind][1], "no layout in scope")

  scope.syntactic_digraph =
    Sublayouts.layoutRecursively (scope,
                  root_layout,
                  LayoutPipeline.runOnLayout,
                  { root_layout })

  -- Step 3: Anchor the graph
  LayoutPipeline.anchor(scope.syntactic_digraph, scope)

  -- Step 4: Apply regardless transforms
  Sublayouts.regardless(scope.syntactic_digraph)

  -- Step 5: Cut edges
  LayoutPipeline.cutEdges(scope.syntactic_digraph)

end



--
-- This method is called by the sublayout rendering pipeline when the
-- algorithm should be invoked for an individual graph. At this point,
-- the sublayouts will already have been collapsed.
--
-- @param scope The graph drawing scope.
-- @param algorithm_class The to-be-applied algorithm class.
-- @param layout_graph A subgraph of the syntactic digraph which is
-- restricted to the current layout and in which sublayouts have
-- been contracted to single nodes.
-- @param layout The layout to which the graph belongs.
--
function LayoutPipeline.runOnLayout(scope, algorithm_class, layout_graph, layout)

  if #layout_graph.vertices < 1 then
    return
  end

  -- The involved main graphs:
  local layout_copy = Digraph.new (layout_graph) --Direct.digraphFromSyntacticDigraph(layout_graph)
  for _,a in ipairs(layout_graph.arcs) do
    local new_a = layout_copy:connect(a.tail,a.head)
    new_a.syntactic_edges = a.syntactic_edges
  end

  -- Step 1: Decompose the graph into connected components, if necessary:
  local syntactic_components
  if algorithm_class.preconditions.tree or algorithm_class.preconditions.connected or layout_graph.options.componentwise then
    syntactic_components = LayoutPipeline.decompose(layout_copy)
    LayoutPipeline.sortComponents(layout_graph.options['component order'], syntactic_components)
  else
    -- Only one component: The graph itself...
    syntactic_components = { layout_copy }
  end

  -- Step 2: For all components do:
  for i,syntactic_component in ipairs(syntactic_components) do

    -- Step 2.1: Reset random number generator to make sure that the
    -- same graph is always typeset in  the same way.
    lib.randomseed(layout_graph.options['random seed'])

    local digraph  = Direct.digraphFromSyntacticDigraph(syntactic_component)

    -- Step 2.3: If requested, remove loops
    if algorithm_class.preconditions.loop_free then
      for _,v in ipairs(digraph.vertices) do
        digraph:disconnect(v,v)
      end
    end

    -- Step 2.4: Precompute the underlying undirected graph
    local ugraph  = Direct.ugraphFromDigraph(digraph)

    -- Step 2.4a: Run preprocessor
    for _,class in ipairs(layout_graph.options.algorithm_phases["preprocessing stack"]) do
      class.new{
        digraph = digraph,
        ugraph = ugraph,
        scope = scope,
        layout = layout,
        layout_graph = layout_graph,
        syntactic_component = syntactic_component,
      }:run()
    end

    -- Step 2.5: Create an algorithm object
    local algorithm = algorithm_class.new{
      digraph = digraph,
      ugraph = ugraph,
      scope = scope,
      layout = layout,
      layout_graph = layout_graph,
      syntactic_component = syntactic_component,
    }

    -- Step 2.7: Compute a spanning tree, if necessary
    if algorithm_class.preconditions.tree then
      local spanning_algorithm_class = syntactic_component.options.algorithm_phases["spanning tree computation"]
      algorithm.spanning_tree =
        spanning_algorithm_class.new{
          ugraph = ugraph,
          events = scope.events
        }:run()
    end

    -- Step 2.8: Compute growth-adjusted sizes
    algorithm.rotation_info = LayoutPipeline.prepareRotateAround(algorithm.postconditions, syntactic_component)
    algorithm.adjusted_bb = Storage.newTableStorage()
    LayoutPipeline.prepareBoundingBoxes(algorithm.rotation_info, algorithm.adjusted_bb, syntactic_component, syntactic_component.vertices)

    -- Step 2.9: Finally, run algorithm on this component!
    if #digraph.vertices > 1 or algorithm_class.run_also_for_single_node
                             or algorithm_class.preconditions.at_least_two_nodes == false then
      -- Main run of the algorithm:
      if algorithm_class.old_graph_model then
        LayoutPipeline.runOldGraphModel(scope, digraph, algorithm_class, algorithm)
      else
        algorithm:run ()
      end
    end

    -- Step 2.9a: Run edge routers
    for _,class in ipairs(layout_graph.options.algorithm_phases["edge routing stack"]) do
      class.new{
        digraph = digraph,
        ugraph = ugraph,
        scope = scope,
        layout = layout,
        layout_graph = layout_graph,
        syntactic_component = syntactic_component,
      }:run()
    end

    -- Step 2.9b: Run postprocessor
    for _,class in ipairs(layout_graph.options.algorithm_phases["postprocessing stack"]) do
      class.new{
        digraph = digraph,
        ugraph = ugraph,
        scope = scope,
        layout = layout,
        layout_graph = layout_graph,
        syntactic_component = syntactic_component,
      }:run()
    end

    -- Step 2.10: Sync the graphs
    digraph:sync()
    ugraph:sync()
    if algorithm.spanning_tree then
      algorithm.spanning_tree:sync()
    end

    -- Step 2.11: Orient the graph
    LayoutPipeline.orient(algorithm.rotation_info, algorithm.postconditions, syntactic_component, scope)
  end

  -- Step 3: Packing:
  LayoutPipeline.packComponents(layout_graph, syntactic_components)

end






---
-- This function is called internally to perform the graph anchoring
-- procedure described in
-- Section~\ref{subsection-library-graphdrawing-anchoring}. These
-- transformations are always performed.
--
-- @param graph A graph
-- @param scope The scope

function LayoutPipeline.anchor(graph, scope)

  -- Step 1: Find anchor node:
  local anchor_node

  local anchor_node_name = graph.options['anchor node']
  if anchor_node_name then
    anchor_node = scope.node_names[anchor_node_name]
  end

  if not graph:contains(anchor_node) then
    anchor_node =
      lib.find (graph.vertices, function (v) return v.options['anchor here'] end) or
      lib.find (graph.vertices, function (v) return v.options['desired at'] end) or
      graph.vertices[1]
  end

  -- Sanity check
  assert(graph:contains(anchor_node), "anchor node is not in graph!")

  local desired = anchor_node.options['desired at'] or graph.options['anchor at']
  local delta = desired - anchor_node.pos

  -- Step 3: Shift nodes
  for _,v in ipairs(graph.vertices) do
    v.pos:shiftByCoordinate(delta)
  end
  for _,a in ipairs(graph.arcs) do
    if a.path then a.path:shiftByCoordinate(delta) end
    for _,e in ipairs(a.syntactic_edges) do
      e.path:shiftByCoordinate(delta)
    end
  end
end



---
-- This method tries to determine in which direction the graph is supposed to
-- grow and in which direction the algorithm will grow the graph. These two
-- pieces of information together produce a necessary rotation around some node.
-- This rotation is returned in a table.
--
-- Note that this method does not actually cause a rotation to happen; this is
-- left to other method.
--
-- @param postconditions The algorithm's postconditions.
-- @param graph An undirected graph
-- @return A table containing the computed information.

function LayoutPipeline.prepareRotateAround(postconditions, graph)

  -- Find the vertex from which we orient
  local swap = true

  local v,_,grow = lib.find (graph.vertices, function (v) return v.options["grow"] end)

  if not v and graph.options["grow"] then
    v,grow,swap = graph.vertices[1], graph.options["grow"], true
  end

  if not v then
    v,_,grow =  lib.find (graph.vertices, function (v) return v.options["grow'"] end)
    swap = false
  end

  if not v and graph.options["grow'"] then
    v,grow,swap = graph.vertices[1], graph.options["grow'"], false
  end

  if not v then
    v, grow, swap = graph.vertices[1], -90, true
  end

  -- Now compute the rotation
  local info = {}
  local growth_direction = (postconditions.upward_oriented and 90) or (postconditions.upward_oriented_swapped and 90)

  if postconditions.upward_oriented_swapped then
    swap = not swap
  end

  if growth_direction == "fixed" then
    info.angle = 0 -- no rotation
  elseif growth_direction then
    info.from_node = v
    info.from_angle = growth_direction/360*2*math.pi
    info.to_angle = grow/360*2*math.pi
    info.swap = swap
    info.angle = info.to_angle - info.from_angle
  else
    info.from_node = v
    local other = lib.find_min(
      graph:outgoing(v),
      function (a)
        if a.head ~= v and a:eventIndex() then
          return a, a:eventIndex()
        end
      end)
    info.to_node = (other and other.head) or
      (graph.vertices[1] == v and graph.vertices[2] or graph.vertices[1])
    info.to_angle = grow/360*2*math.pi
    info.swap = swap
    info.angle = info.to_angle - math.atan2(info.to_node.pos.y - v.pos.y, info.to_node.pos.x - v.pos.x)
  end

  return info
end



---
-- Compute growth-adjusted node sizes.
--
-- For each node of the graph, compute bounding box of the node that
-- results when the node is rotated so that it is in the correct
-- orientation for what the algorithm assumes.
--
-- The ``bounding box'' actually consists of the fields
-- %
-- \begin{itemize}
--   \item |sibling_pre|,
--   \item |sibling_post|,
--   \item |layer_pre|, and
--   \item |layer_post|,
-- \end{itemize}
-- %
-- which correspond to ``min x'', ``min y'', ``min y'', and ``max y''
-- for a tree growing up.
--
-- The computation of the ``bounding box'' treats a centered circle in
-- a special way, all other shapes are currently treated like a
-- rectangle.
--
-- @param rotation_info The table computed by the function prepareRotateAround
-- @param packing_storage A storage in which the computed distances are stored.
-- @param graph     An graph
-- @param vertices  An array of to-be-prepared vertices inside graph

function LayoutPipeline.prepareBoundingBoxes(rotation_info, adjusted_bb, graph, vertices)

  local angle = assert(rotation_info.angle, "angle field missing")
  local swap  = rotation_info.swap

  for _,v in ipairs(vertices) do
    local bb = adjusted_bb[v]
    local a  = angle

    if v.shape == "circle" then
      a = 0 -- no rotation for circles.
    end

    -- Fill the bounding box field,
    bb.sibling_pre = math.huge
    bb.sibling_post = -math.huge
    bb.layer_pre = math.huge
    bb.layer_post = -math.huge

    local c = math.cos(angle)
    local s = math.sin(angle)
    for _,p in ipairs(v.path:coordinates()) do
      local x =  p.x*c + p.y*s
      local y = -p.x*s + p.y*c

      bb.sibling_pre = math.min (bb.sibling_pre, x)
      bb.sibling_post = math.max (bb.sibling_post, x)
      bb.layer_pre = math.min (bb.layer_pre, y)
      bb.layer_post = math.max (bb.layer_post, y)
    end

    -- Flip sibling per and post if flag:
    if swap then
      bb.sibling_pre, bb.sibling_post = -bb.sibling_post, -bb.sibling_pre
    end
  end
end





--
-- Rotate the whole graph around a point
--
-- Causes the graph to be rotated around \meta{around} so that what
-- used to be the |from_angle| becomes the |to_angle|. If the flag |swap|
-- is set, the graph is additionally swapped along the |to_angle|.
--
-- @param graph The to-be-rotated (undirected) graph
-- @param around_x The $x$-coordinate of the point around which the graph should be rotated
-- @param around_y The $y$-coordinate
-- @param from An ``old'' angle
-- @param to A ``new'' angle
-- @param swap A boolean that, when true, requests that the graph is
--             swapped (flipped) along the new angle

function LayoutPipeline.rotateGraphAround(graph, around_x, around_y, from, to, swap)

  -- Translate to origin
  local t = Transform.new_shift(-around_x, -around_y)

  -- Rotate to zero degrees:
  t = Transform.concat(Transform.new_rotation(-from), t)

  -- Swap
  if swap then
    t = Transform.concat(Transform.new_scaling(1,-1), t)
  end

  -- Rotate to from degrees:
  t = Transform.concat(Transform.new_rotation(to), t)

  -- Translate back
  t = Transform.concat(Transform.new_shift(around_x, around_y), t)

  for _,v in ipairs(graph.vertices) do
    v.pos:apply(t)
  end
  for _,a in ipairs(graph.arcs) do
    for _,p in ipairs(a:pointCloud()) do
      p:apply(t)
    end
  end
end



--
-- Orient the whole graph using two nodes
--
-- The whole graph is rotated so that the line from the first node to
-- the second node has the given angle. If swap is set to true, the
-- graph is also flipped along this line.
--
-- @param graph
-- @param first_node
-- @param seond_node
-- @param target_angle
-- @param swap

function LayoutPipeline.orientTwoNodes(graph, first_node, second_node, target_angle, swap)
  if first_node and second_node then
    -- Compute angle between first_node and second_node:
    local x = second_node.pos.x - first_node.pos.x
    local y = second_node.pos.y - first_node.pos.y

    local angle = math.atan2(y,x)
    LayoutPipeline.rotateGraphAround(graph, first_node.pos.x,
               first_node.pos.y, angle, target_angle, swap)
  end
end



---
-- Performs a post-layout orientation of the graph by performing the
-- steps documented in Section~\ref{subsection-library-graphdrawing-standard-orientation}.
--
-- @param rotation_info The info record computed by the function |prepareRotateAround|.
-- @param postconditions The algorithm's postconditions.
-- @param graph A to-be-oriented graph.
-- @param scope The graph drawing scope.

function LayoutPipeline.orient(rotation_info, postconditions, graph, scope)

  -- Sanity check
  if #graph.vertices < 2 then return end

  -- Step 1: Search for global graph orient options:
  local function f (orient, tail, head, flag)
    if orient and head and tail then
      local n1 = scope.node_names[tail]
      local n2 = scope.node_names[head]
      if graph:contains(n1) and graph:contains(n2) then
        LayoutPipeline.orientTwoNodes(graph, n1, n2, orient/360*2*math.pi, flag)
        return true
      end
    end
  end
  if f(graph.options["orient"], graph.options["orient tail"],graph.options["orient head"], false) then return end
  if f(graph.options["orient'"], graph.options["orient tail"],graph.options["orient head"], true) then return end
  local tail, head = string.match(graph.options["horizontal"] or "", "^(.*) to (.*)$")
  if f(0, tail, head, false) then return end
  local tail, head = string.match(graph.options["horizontal'"] or "", "^(.*) to (.*)$")
  if f(0, tail, head, true) then return end
  local tail, head = string.match(graph.options["vertical"] or "", "^(.*) to (.*)$")
  if f(-90, tail, head, false) then return end
  local tail, head = string.match(graph.options["vertical'"] or "", "^(.*) to (.*)$")
  if f(-90, tail, head, true) then return end

  -- Step 2: Search for a node with the orient option:
  for _, v in ipairs(graph.vertices) do
    local function f (key, flag)
      local orient = v.options[key]
      local head   = v.options["orient head"]
      local tail   = v.options["orient tail"]

      if orient and head then
        local n2 = scope.node_names[head]
        if graph:contains(n2) then
          LayoutPipeline.orientTwoNodes(graph, v, n2, orient/360*2*math.pi, flag)
          return true
        end
          elseif orient and tail then
        local n1 = scope.node_names[tail]
        if graph:contains(n1) then
          LayoutPipeline.orientTwoNodes(graph, n1, v, orient/360*2*math.pi, flag)
          return true
        end
      end
    end
    if f("orient", false) then return end
    if f("orient'", true) then return end
  end

  -- Step 3: Search for an edge with the orient option:
  for _, a in ipairs(graph.arcs) do
    if a:options("orient",true) then
      return LayoutPipeline.orientTwoNodes(graph, a.tail, a.head, a:options("orient")/360*2*math.pi, false)
    end
    if a:options("orient'",true) then
      return LayoutPipeline.orientTwoNodes(graph, a.tail, a.head, a:options("orient'")/360*2*math.pi, true)
    end
  end

  -- Step 4: Search two nodes with a desired at option:
  local first, second, third

  for _, v in ipairs(graph.vertices) do
    if v.options['desired at'] then
      if first then
        if second then
          third = v
          break
        else
          second = v
        end
          else
        first = v
      end
    end
  end

  if second then
    local a = first.options['desired at']
    local b = second.options['desired at']
    return LayoutPipeline.orientTwoNodes(graph, first, second, math.atan2(b.y-a.y,b.x-a.x), false)
  end

  -- Computed during preprocessing:
  if rotation_info.from_node and postconditions.fixed ~= true then
    local x = rotation_info.from_node.pos.x
    local y = rotation_info.from_node.pos.y
    local from_angle = rotation_info.from_angle or math.atan2(rotation_info.to_node.pos.y - y, rotation_info.to_node.pos.x - x)

    LayoutPipeline.rotateGraphAround(graph, x, y, from_angle, rotation_info.to_angle, rotation_info.swap)
  end
end




---
-- This internal function is called to decompose a graph into its
-- components. Whether or not this function is called depends on
-- whether the precondition |connected| is set for the algorithm class
-- and whether the |componentwise| key is used.
--
-- @param graph A to-be-decomposed graph
--
-- @return An array of graph objects that represent the connected components of the graph.

function LayoutPipeline.decompose (digraph)

  -- The list of connected components (node sets)
  local components = {}

  -- Remember, which graphs have already been visited
  local visited = {}

  for _,v in ipairs(digraph.vertices) do
    if not visited[v] then
      -- Start a depth-first-search of the graph, starting at node n:
      local stack = { v }
      local component = Digraph.new {
        syntactic_digraph = digraph.syntactic_digraph,
        options = digraph.options
      }

      while #stack >= 1 do
        local tos = stack[#stack]
        stack[#stack] = nil -- pop

        if not visited[tos] then

          -- Visit pos:
          component:add { tos }
          visited[tos] = true

          -- Push all unvisited neighbors:
          for _,a in ipairs(digraph:incoming(tos)) do
            local neighbor = a.tail
            if not visited[neighbor] then
              stack[#stack+1] = neighbor -- push
            end
          end
          for _,a in ipairs(digraph:outgoing(tos)) do
            local neighbor = a.head
            if not visited[neighbor] then
              stack[#stack+1] = neighbor -- push
            end
          end
        end
      end

      -- Ok, vertices will now contain all vertices reachable from n.
      components[#components+1] = component
    end
  end

  if #components < 2 then
    return { digraph }
  end

  for _,c in ipairs(components) do
    table.sort (c.vertices, function (u,v) return u.event.index < v.event.index end)
    for _,v in ipairs(c.vertices) do
      for _,a in ipairs(digraph:outgoing(v)) do
        local new_a = c:connect(a.tail, a.head)
        new_a.syntactic_edges = a.syntactic_edges
      end
      for _,a in ipairs(digraph:incoming(v)) do
        local new_a = c:connect(a.tail, a.head)
        new_a.syntactic_edges = a.syntactic_edges
      end
    end
  end

  return components
end




-- Handling of component order
--
-- LayoutPipeline are ordered according to a function that is stored in
-- a key of the |LayoutPipeline.component_ordering_functions| table
-- whose name is the graph option |component order|.
--
-- @param component_order An ordering method
-- @param subgraphs A list of to-be-sorted subgraphs

function LayoutPipeline.sortComponents(component_order, subgraphs)
  if component_order then
    local f = LayoutPipeline.component_ordering_functions[component_order]
    if f then
      table.sort (subgraphs, f)
    end
  end
end


-- Right now, we hardcode the functions here. Perhaps make this
-- dynamic in the future. Could easily be done on the tikzlayer,
-- actually.

LayoutPipeline.component_ordering_functions = {
  ["increasing node number"] =
    function (g,h)
      if #g.vertices == #h.vertices then
        return g.vertices[1].event.index < h.vertices[1].event.index
      else
        return #g.vertices < #h.vertices
      end
    end,
  ["decreasing node number"] =
    function (g,h)
      if #g.vertices == #h.vertices then
        return g.vertices[1].event.index < h.vertices[1].event.index
      else
        return #g.vertices > #h.vertices
      end
    end,
  ["by first specified node"] = nil,
}




local function compute_rotated_bb(vertices, angle, sep, bb)

  local r = Transform.new_rotation(-angle)

  for _,v in ipairs(vertices) do
    -- Find the rotated bounding box field,
    local t = Transform.concat(r,Transform.new_shift(v.pos.x, v.pos.y))

    local min_x = math.huge
    local max_x = -math.huge
    local min_y = math.huge
    local max_y = -math.huge

    for _,e in ipairs(v.path) do
      if type(e) == "table" then
        local c = e:clone()
        c:apply(t)

        min_x = math.min (min_x, c.x)
        max_x = math.max (max_x, c.x)
        min_y = math.min (min_y, c.y)
        max_y = math.max (max_y, c.y)
      end
    end

    -- Enlarge by sep:
    min_x = min_x - sep
    max_x = max_x + sep
    min_y = min_y - sep
    max_y = max_y + sep

    local _,_,_,_,c_x,c_y = v:boundingBox()
    local center = Coordinate.new(c_x,c_y)

    center:apply(t)

    bb[v].min_x = min_x
    bb[v].max_x = max_x
    bb[v].min_y = min_y
    bb[v].max_y = max_y
    bb[v].c_y = center.y
  end
end



---
-- This internal function packs the components of a graph. See
-- Section~\ref{subsection-gd-component-packing} for details.
--
-- @param graph The graph
-- @param components A list of components

function LayoutPipeline.packComponents(syntactic_digraph, components)

  local vertices = Storage.newTableStorage()
  local bb = Storage.newTableStorage()

  -- Step 1: Preparation, rotation to target direction
  local sep = syntactic_digraph.options['component sep']
  local angle = syntactic_digraph.options['component direction']/180*math.pi

  local mark = {}
  for _,c in ipairs(components) do

    -- Setup the lists of to-be-considered nodes
    local vs = {}
    for _,v in ipairs(c.vertices) do
      vs [#vs + 1] = v
    end

    for _,a in ipairs(c.arcs) do
      for _,p in ipairs(a:pointCloud()) do
        vs [#vs + 1] = Vertex.new { pos = p }
      end
    end
    vertices[c] = vs

    compute_rotated_bb(vs, angle, sep/2, bb)
  end

  local x_shifts = { 0 }
  local y_shifts = {}

  -- Step 2: Vertical alignment
  for i,c in ipairs(components) do
    local max_max_y = -math.huge
    local max_center_y = -math.huge
    local min_min_y = math.huge
    local min_center_y = math.huge

    for _,v in ipairs(c.vertices) do
      local info = bb[v]
      max_max_y = math.max(info.max_y, max_max_y)
      max_center_y = math.max(info.c_y, max_center_y)
      min_min_y = math.min(info.min_y, min_min_y)
      min_center_y = math.min(info.c_y, min_center_y)
    end

    -- Compute alignment line
    local valign = syntactic_digraph.options['component align']
    local line
    if valign == "counterclockwise bounding box" then
      line = max_max_y
    elseif valign == "counterclockwise" then
      line = max_center_y
    elseif valign == "center" then
      line = (max_max_y + min_min_y) / 2
    elseif valign == "clockwise" then
      line = min_center_y
    elseif valign == "first node" then
      line = bb[c.vertices[1]].c_y
    else
      line = min_min_y
    end

    -- Overruled?
    for _,v in ipairs(c.vertices) do
      if v.options['align here'] then
        line = bb[v].c_y
        break
      end
    end

    -- Ok, go!
    y_shifts[i] = -line

    -- Adjust nodes:
    for _,v in ipairs(vertices[c]) do
      local info = bb[v]
      info.min_y = info.min_y - line
      info.max_y = info.max_y - line
      info.c_y = info.c_y - line
    end
  end

  -- Step 3: Horizontal alignment
  local y_values = {}

  for _,c in ipairs(components) do
    for _,v in ipairs(vertices[c]) do
      local info = bb[v]
      y_values[#y_values+1] = info.min_y
      y_values[#y_values+1] = info.max_y
      y_values[#y_values+1] = info.c_y
    end
  end

  table.sort(y_values)

  local y_ranks = {}
  local right_face = {}
  for i=1,#y_values do
    y_ranks[y_values[i]] = i
    right_face[i] = -math.huge
  end



  for i=1,#components-1 do
    -- First, update right_face:
    local touched = {}

    for _,v in ipairs(vertices[components[i]]) do
      local info = bb[v]
      local border = info.max_x

      for i=y_ranks[info.min_y],y_ranks[info.max_y] do
        touched[i] = true
        right_face[i] = math.max(right_face[i], border)
      end
    end

    -- Fill up the untouched entries:
    local right_max = -math.huge
    for i=1,#y_values do
      if not touched[i] then
        -- Search for next and previous touched
        local interpolate = -math.huge
        for j=i+1,#y_values do
          if touched[j] then
            interpolate = math.max(interpolate,right_face[j] - (y_values[j] - y_values[i]))
            break
          end
        end
        for j=i-1,1,-1 do
          if touched[j] then
            interpolate = math.max(interpolate,right_face[j] - (y_values[i] - y_values[j]))
            break
          end
        end
        right_face[i] = math.max(interpolate,right_face[i])
      end
      right_max = math.max(right_max, right_face[i])
    end

    -- Second, compute the left face
    local touched = {}
    local left_face = {}
    for i=1,#y_values do
      left_face[i] = math.huge
    end
    for _,v in ipairs(vertices[components[i+1]]) do
      local info = bb[v]
      local border = info.min_x

      for i=y_ranks[info.min_y],y_ranks[info.max_y] do
        touched[i] = true
        left_face[i] = math.min(left_face[i], border)
      end
    end

    -- Fill up the untouched entries:
    local left_min = math.huge
    for i=1,#y_values do
      if not touched[i] then
        -- Search for next and previous touched
        local interpolate = math.huge
        for j=i+1,#y_values do
          if touched[j] then
            interpolate = math.min(interpolate,left_face[j] + (y_values[j] - y_values[i]))
            break
          end
        end
        for j=i-1,1,-1 do
          if touched[j] then
            interpolate = math.min(interpolate,left_face[j] + (y_values[i] - y_values[j]))
            break
          end
        end
        left_face[i] = interpolate
      end
      left_min = math.min(left_min, left_face[i])
    end

    -- Now, compute the shift.
    local shift = -math.huge

    if syntactic_digraph.options['component packing'] == "rectangular" then
      shift = right_max - left_min
    else
      for i=1,#y_values do
        shift = math.max(shift, right_face[i] - left_face[i])
      end
    end

    -- Adjust nodes:
    x_shifts[i+1] = shift
    for _,v in ipairs(vertices[components[i+1]]) do
      local info = bb[v]
      info.min_x = info.min_x + shift
      info.max_x = info.max_x + shift
    end
  end

  -- Now, rotate shifts
  for i,c in ipairs(components) do
    local x =  x_shifts[i]*math.cos(angle) - y_shifts[i]*math.sin(angle)
    local y =  x_shifts[i]*math.sin(angle) + y_shifts[i]*math.cos(angle)

    for _,v in ipairs(vertices[c]) do
      v.pos.x = v.pos.x + x
      v.pos.y = v.pos.y + y
    end
  end
end







--
-- Store for each begin/end event the index of
-- its corresponding end/begin event
--
-- @param events An event list

prepare_events =
  function (events)
    local stack = {}

    for i=1,#events do
      if events[i].kind == "begin" then
        stack[#stack + 1] = i
      elseif events[i].kind == "end" then
        local tos = stack[#stack]
        stack[#stack] = nil -- pop

        events[tos].end_index = i
        events[i].begin_index = tos
      end
    end
  end



---
-- Cut the edges. This function handles the ``cutting'' of edges. The
-- idea is that every edge is a path going from the center of the from
-- node to the center of the target node. Now, we intersect this path
-- with the path of the start node and cut away everything before this
-- intersection. Likewise, we intersect the path with the head node
-- and, again, cut away everything following the intersection.
--
-- These cuttings are not done if appropriate options are set.

function LayoutPipeline.cutEdges(graph)

  for _,a in ipairs(graph.arcs) do
    for _,e in ipairs(a.syntactic_edges) do
      local p = e.path
      p:makeRigid()
      local orig = p:clone()

      if e.options['tail cut'] and e.tail.options['cut policy'] == "as edge requests"
        or e.tail.options['cut policy'] == "all" then

        local vpath = e.tail.path:clone()
        vpath:shiftByCoordinate(e.tail.pos)

        local x = p:intersectionsWith (vpath)

        if #x > 0 then
          p:cutAtBeginning(x[1].index, x[1].time)
        end
      end

      if e.options['head cut'] and e.head.options['cut policy'] == "as edge requests"
        or e.head.options['cut policy'] == "all" then

        local vpath = e.head.path:clone()
        vpath:shiftByCoordinate(e.head.pos)
        x = p:intersectionsWith (vpath)
        if #x > 0 then
          p:cutAtEnd(x[#x].index, x[#x].time)
        else
          -- Check whether there was an intersection with the original
          --path:
          local x2 = orig:intersectionsWith (vpath)
          if #x2 > 0 then
            -- Ok, after cutting the tail vertex, there is no longer
            -- an intersection with the head vertex, but there used to
            -- be one. This means that the vertices overlap and the
            -- path should be ``inside'' them. Hmm...
            if e.options['allow inside edges'] and #p > 1 then
              local from = p[2]
              local to = x2[1].point
              p:clear()
              p:appendMoveto(from)
              p:appendLineto(to)
            else
              p:clear()
            end
          end
        end
      end
    end
  end
end






-- Deprecated stuff

local Node = require "pgf.gd.deprecated.Node"
local Graph = require "pgf.gd.deprecated.Graph"
local Edge = require "pgf.gd.deprecated.Edge"
local Cluster = require "pgf.gd.deprecated.Cluster"





local unique_count = 0

local function compatibility_digraph_to_graph(scope, g)
  local graph = Graph.new()

  -- Graph options
  graph.options = g.options
  graph.orig_digraph = g

  -- Events
  for i,e in ipairs(scope.events) do
    graph.events[i] = e
  end

  -- Nodes
  for _,v in ipairs(g.vertices) do
    if not v.name then
      -- compat needs unique name
      v.name = "auto generated node nameINTERNAL" .. unique_count
      unique_count = unique_count + 1
    end
    local minX, minY, maxX, maxY = v:boundingBox()
    local node = Node.new{
      name = v.name,
      tex = {
        tex_node = v.tex and v.tex.stored_tex_box_number,
        shape = v.shape,
        minX = minX,
        maxX = maxX,
        minY = minY,
        maxY = maxY,
      },
      options = v.options,
      event_index = v.event.index,
      index = v.event.index,
      orig_vertex = v,
    }
    graph:addNode(node)
    graph.events[v.event.index or (#graph.events+1)] = { kind = 'node', parameters = node }
  end

  -- Edges
  local mark = Storage.new()
  for _,a in ipairs(g.arcs) do
    local da = g.syntactic_digraph:arc(a.tail, a.head)
    if da then
      for _,m in ipairs(da.syntactic_edges) do
        if not mark[m] then
          mark[m] = true
          local from_node = graph:findNode(da.tail.name)
          local to_node = graph:findNode(da.head.name)
          local edge = graph:createEdge(from_node, to_node, m.direction, nil, m.options, nil)
          edge.event_index = m.event.index
          edge.orig_m = m
          graph.events[m.event.index] = { kind = 'edge', parameters = edge }
        end
      end
    end
    local da = g.syntactic_digraph:arc(a.head, a.tail)
    if da then
      for _,m in ipairs(da.syntactic_edges) do
        if not mark[m] then
          mark[m] = true
          local from_node = graph:findNode(da.tail.name)
          local to_node = graph:findNode(da.head.name)
          local edge = graph:createEdge(from_node, to_node, m.direction, nil, m.options, nil)
          edge.event_index = m.event.index
          edge.orig_m = m
          graph.events[m.event.index] = { kind = 'edge', parameters = edge }
        end
      end
    end
  end

  table.sort(graph.edges, function(e1,e2) return e1.event_index < e2.event_index end)
  for _,n in ipairs (graph.nodes) do
    table.sort(n.edges, function(e1,e2) return e1.event_index < e2.event_index end)
  end


  -- Clusters
  for _, c in ipairs(scope.collections['same layer'] or {}) do
    cluster = Cluster.new("cluster" .. unique_count)
    unique_count = unique_count+1
    graph:addCluster(cluster)
    for _,v in ipairs(c.vertices) do
      if g:contains(v) then
        cluster:addNode(graph:findNode(v.name))
      end
    end
  end

  return graph
end


local function compatibility_graph_to_digraph(graph)
  for _,n in ipairs(graph.nodes) do
    n.orig_vertex.pos.x = n.pos.x
    n.orig_vertex.pos.y = n.pos.y
  end
  for _,e in ipairs(graph.edges) do
    if #e.bend_points > 0 then
      local c = {}
      for _,x in ipairs(e.bend_points) do
        c[#c+1] = Coordinate.new (x.x, x.y)
      end
      e.orig_m:setPolylinePath(c)
    end
  end
end





function LayoutPipeline.runOldGraphModel(scope, digraph, algorithm_class, algorithm)

  local graph = compatibility_digraph_to_graph(scope, digraph)

  algorithm.graph = graph
  graph:registerAlgorithm(algorithm)

  -- If requested, remove loops
  if algorithm_class.preconditions.loop_free then
    Simplifiers:removeLoopsOldModel(algorithm)
  end

  -- If requested, collapse multiedges
  if algorithm_class.preconditions.simple then
    Simplifiers:collapseMultiedgesOldModel(algorithm)
  end

  if #graph.nodes > 1 then
    -- Main run of the algorithm:
    algorithm:run ()
  end

  -- If requested, expand multiedges
  if algorithm_class.preconditions.simple then
    Simplifiers:expandMultiedgesOldModel(algorithm)
  end

  -- If requested, restore loops
  if algorithm_class.preconditions.loop_free then
    Simplifiers:restoreLoopsOldModel(algorithm)
  end

  compatibility_graph_to_digraph(graph)
end




-- Done

return LayoutPipeline
