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
-- This class provides the interface between a display
-- layer (like \tikzname\ or a graph editor) and graph drawing
-- system. Another class, |InterfaceToAlgorithms|, binds the algorithm
-- layer (which are written in Lua) to the graph drawing system.
--
-- The functions declared here are independent of the actual display
-- layer. Rather, the differences between the layers are encapsulated
-- by subclasses of the |Binding| class, see that class for
-- details. Thus, when a new display layer is written, the present
-- class is \emph{used}, but not \emph{modified}. Instead, only a new
-- binding is created and all display layer specific interaction is
-- put there.
--
-- The job of this class is to provide convenient methods that can be
-- called by the display layer. For instance, it provides methods for
-- starting a graph drawing scope, managing the stack of such scope,
-- adding a node to a graph and so on.

local InterfaceToDisplay = {}

-- Namespace
require("pgf.gd.interface").InterfaceToDisplay = InterfaceToDisplay


-- Imports
local InterfaceCore  = require "pgf.gd.interface.InterfaceCore"
local Scope          = require "pgf.gd.interface.Scope"

local Binding        = require "pgf.gd.bindings.Binding"

local Sublayouts     = require "pgf.gd.control.Sublayouts"
local LayoutPipeline = require "pgf.gd.control.LayoutPipeline"

local Digraph        = require "pgf.gd.model.Digraph"
local Vertex         = require "pgf.gd.model.Vertex"
local Edge           = require "pgf.gd.model.Edge"
local Collection     = require "pgf.gd.model.Collection"

local Storage        = require "pgf.gd.lib.Storage"
local LookupTable    = require "pgf.gd.lib.LookupTable"
local Event          = require "pgf.gd.lib.Event"

local lib            = require "pgf.gd.lib"


-- Forward declarations
local get_current_options_table
local render_collections
local push_on_option_stack
local vertex_created

-- Local objects

local phase_unique       = {}  -- a unique handle
local collections_unique = {}  -- a unique handle
local option_cache       = nil -- The option cache




---
-- Initialize the binding. This function is called once by the display
-- layer at the very beginning. For instance, \tikzname\ does the
-- following call:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--InterfaceToDisplay.bind(require "pgf.gd.bindings.BindingToPGF")
--\end{codeexample}
--
-- Inside this call, many standard declarations will be executed, that
-- is, the declared binding will be used immediately.
--
-- Subsequently, the |binding| field of the |InterfaceCore| can be used.
--
-- @param class A subclass of |Binding|.

function InterfaceToDisplay.bind(class)
  assert (not InterfaceCore.binding, "binding already initialized")

  -- Create a new object
  InterfaceCore.binding = setmetatable({}, class)

  -- Load these libraries, which contain many standard declarations:
  require "pgf.gd.model.library"
  require "pgf.gd.control.library"
end




---
-- Start a graph drawing scope. Note that this is not the same as
-- starting a subgraph / sublayout, which are local to a graph drawing
-- scope: When a new graph drawing scope is started, it is pushed on
-- top of a stack of graph drawing scopes and all other ``open''
-- scopes are no longer directly accessible. All method calls to an
-- |Interface...| object will refer to this newly created scope until
-- either a new scope is opened or until the current scope is closed
-- once more.
--
-- Each graph drawing scope comes with a syntactic digraph that is
-- build using methods like |addVertex| or |addEdge|.
--
-- @param height The to-be-used height of the options stack. All
-- options above this height will be popped prior to attacking the
-- options to the syntactic digraph.

function InterfaceToDisplay.beginGraphDrawingScope(height)

  -- Create a new scope table
  local scope = Scope.new {}

  -- Setup syntactic digraph:
  local g = scope.syntactic_digraph

  g.options = get_current_options_table(height)
  g.syntactic_digraph = g
  g.scope = scope

  -- Push scope:
  InterfaceCore.scopes[#InterfaceCore.scopes + 1] = scope
end



---
-- Arranges the current graph using the specified algorithm and options.
--
-- This function should be called after the graph drawing scope has
-- been opened and the syntactic digraph has been completely
-- specified. It will now start running the algorithm specified
-- through the |algorithm_phase| options.
--
-- Internally, this function creates a coroutine that will run the current graph
-- drawing algorithm. Coroutines are needed since a graph drawing
-- algorithm may choose to create a new node. In this case, the
-- algorithm needs to be suspended and control must be returned back
-- to the display layer, so that the node can be typeset in order to
-- determine the precise size information. Once this is done, control
-- must be passed back to the exact point inside the algorithm where
-- the node was created. Clearly, all of these actions are exactly
-- what coroutines are for.
--
-- @return Time it took to run the algorithm

function InterfaceToDisplay.runGraphDrawingAlgorithm()

  -- Time things
  local start = os.clock()

  -- Setup
  local scope = InterfaceCore.topScope()
  assert(not scope.coroutine, "coroutine already created for current gd scope")

  -- The actual drawing function
  local function run ()
    if #scope.syntactic_digraph.vertices == 0 then
      -- Nothing needs to be done
      return
    end

    LayoutPipeline.run(scope)
  end

  scope.coroutine = coroutine.create(run)

  -- Run it:
  InterfaceToDisplay.resumeGraphDrawingCoroutine()

  -- End timing:
  local stop = os.clock()

  return stop - start
end


---
-- Resume the graph drawing coroutine.
--
-- This function is the work horse of the coroutine management. It
-- gets called whenever control passes back from the display layer to
-- the algorithm level. We resume the graph drawing coroutine so that the
-- algorithm can start/proceed. The tricky part is when the algorithm
-- yields, but is not done. In this case, the code needed for creating
-- a new node is passed back to the display layer through the binding,
-- which must then execute the code and then resuming the coroutine.
--
function InterfaceToDisplay.resumeGraphDrawingCoroutine()

  -- Setup
  local scope = InterfaceCore.topScope()
  local binding = InterfaceCore.binding

  -- Asserts
  assert(scope.coroutine, "coroutine not created for current gd scope")

  -- Run
  local ok, text = coroutine.resume(scope.coroutine)
  assert(ok, text)
  if coroutine.status(scope.coroutine) ~= "dead" then
    -- Ok, ask binding to continue
    binding:resumeGraphDrawingCoroutine(text)
  end
end



--- Ends the current graph drawing scope.
--
function InterfaceToDisplay.endGraphDrawingScope()
  assert(#InterfaceCore.scopes > 0, "no gd scope open")
  InterfaceCore.scopes[#InterfaceCore.scopes] = nil -- pop
end




---
-- Creates a new vertex in the syntactic graph of the current graph
-- drawing scope. The display layer should call this function for each
-- node of the graph. The |name| must be a unique string identifying
-- the node. The newly created vertex will be added to the syntactic
-- digraph. The binding function |everyVertexCreation| will then be
-- called, allowing the binding to store information regarding the newly
-- created vertex.
--
-- For each vertex an event will be created in the event
-- sequence. This event will have the kind |"node"| and its
-- |parameter| will be the vertex.
--
-- @param name Name of the vertex.
--
-- @param shape The shape of the vertex such as |"circle"| or
-- |"rectangle"|. This shape may help a graph drawing algorithm
-- figuring out how the node should be placed.
--
-- @param path A |Path| object representing the vertex's path.
--
-- @param height The to-be-used height of the options stack. All
-- options above this height will be popped prior to attacking the
-- options to the syntactic digraph.
--
-- @param binding_infos These options are passed to and are specific
-- to the current |Binding|.
--
-- @param anchors A table of anchors (mapping anchor positions to
-- |Coordinates|).


function InterfaceToDisplay.createVertex(name, shape, path, height, binding_infos, anchors)

  -- Setup
  local scope = InterfaceCore.topScope()
  local binding = InterfaceCore.binding

  -- Does vertex already exist?
  local v = scope.node_names[name]
  assert (not v or not v.created_on_display_layer, "node already created")

  -- Create vertex
  if not v then
    v = Vertex.new {
      name                     = name,
      shape                    = shape,
      kind                     = "node",
      path                     = path,
      options                  = get_current_options_table(height),
      anchors                  = anchors,
    }

    vertex_created(v,scope)
  else
    assert(v.kind == "subgraph node", "subgraph node expected")
    v.shape   = shape
    v.path    = path
    v.anchors = anchors
  end

  v.created_on_display_layer = true

  -- Call binding
  binding.storage[v] = binding_infos
  binding:everyVertexCreation(v)
end


-- This is a helper function
function vertex_created(v,scope)

  -- Create Event
  local e = InterfaceToDisplay.createEvent ("node", v)
  v.event = e

  -- Create name lookup
  scope.node_names[v.name] = v

  -- Add vertex to graph
  scope.syntactic_digraph:add {v}

  -- Add to collections
  for _,c in ipairs(v.options.collections) do
    LookupTable.addOne(c.vertices, v)
  end

end



---
-- Creates a new vertex in the syntactic graph of the current graph
-- drawing scope that is a subgraph vertex. Such a vertex
-- ``surrounds'' the vertices of a subgraph. The special property of a
-- subgraph node opposed to a normal node is that it is created only
-- after the subgraph has been laid out. However, the difference to a
-- collection like |hyper| is that the node is available immediately as
-- a normal node in the sense that you can connect edges to it.
--
-- What happens internally is that subgraph nodes get ``registered''
-- immediately both on the display level and on the algorithm level,
-- but the actual node is only created inside the layout pipeline
-- using a callback of the binding. The present function is used to
-- perform this registering. The node creation happens when the
-- innermost layout in which the subgraph node is declared has
-- finished. For each subgraph node, a collection is created that
-- contains all vertices (and edges) being part of the subgraph. For
-- this reason, this method is a |push...| method, since it pushes
-- something on the options stack.
--
-- The |init| parameter will be used during the creation of the node,
-- see |Binding:createVertex| for details on the fields. Note that
-- |init.text| is often not displayed for such ``vast'' nodes as those
-- created for whole subgraphs, but a shape may use it nevertheless
-- (for instance, one might display this text at the top of the node
-- or, in case of a \textsc{uml} package, in a special box above the
-- actual node).
--
-- The |init.generated_options| will be augmented by additional
-- key--value pairs when the vertex is created:
-- %
-- \begin{itemize}
--   \item The key |subgraph point cloud| will have as its value a
--     string that is be a list of points (without separating commas)
--     like |"(10pt,20pt)(0pt,0pt)(30pt,40pt)"|, always in
--     this syntax. The list will contain all points inside the
--     subgraph. In particular, a bounding box around these points will
--     encompass all nodes and bend points of the subgraph.
--     The bounding box of this point cloud is guaranteed to be centered on
--     the origin.
--   \item The key |subgraph bounding box width| will have as its value
--     the width of a bounding box (in \TeX\ points, as a string with the
--     suffix |"pt"|).
--   \item The key |subgraph bounding box height| stores the height of a
--     bounding box.
-- \end{itemize}
--
-- @param name The name of the node.
-- @param height Height of the options stack. Note that this method
-- pushes something (namely a collection) on the options stack.
-- @param info A table passed to |Binding:createVertex|, see that function.
--
function InterfaceToDisplay.pushSubgraphVertex(name, height, info)

  -- Setup
  local scope = InterfaceCore.topScope()
  local binding = InterfaceCore.binding

  -- Does vertex already exist?
  assert (not scope.node_names[name], "node already created")

  -- Create vertex
  local v = Vertex.new {
    name    = name,
    kind    = "subgraph node",
    options = get_current_options_table(height-1)
  }

  vertex_created(v,scope)

  -- Store info
  info.generated_options = info.generated_options or {}
  info.name              = name
  v.subgraph_info        = info

  -- Create collection and link it to v
  local _, _, entry = InterfaceToDisplay.pushOption(InterfaceCore.subgraph_node_kind, nil, height)
  v.subgraph_collection = entry.value
  v.subgraph_collection.subgraph_node = v

  -- Find parent collection in options stack:
  local collections = v.options.collections
  for i=#collections,1,-1 do
    if collections[i].kind == InterfaceCore.sublayout_kind then
      v.subgraph_collection.parent_layout = collections[i]
      break
    end
  end
end



---
-- Add options for an already existing vertex.
--
-- This function allows you to add options to an already existing
-- vertex. The options that will be added are all options on the
-- current options stack; they will overwrite existing options of the
-- same name. For collections, the vertex stays in all collections it
-- used to, it is only added to all collections that are currently on
-- the options stack.
--
-- @param name      Name of the vertex.
-- @param height    The option stack height.

function InterfaceToDisplay.addToVertexOptions(name, height)

  -- Setup
  local scope = InterfaceCore.topScope()

  -- Does vertex already exist?
  local v = assert (scope.node_names[name], "node is missing, cannot add options")

  v.options = get_current_options_table(height, v.options)

  -- Add to collections
  for _,c in ipairs(v.options.collections) do
    LookupTable.addOne(c.vertices, v)
  end

end





---
-- Creates a new edge in the syntactic graph of the current graph
-- drawing scope. The display layer should call this function for each
-- edge that is created. Both the |from| vertex and the |to| vertex
-- must exist (have been created through |createVertex|) prior to your
-- being able to call this function.
--
-- After the edge has been created, the binding layer's function
-- |everyEdgeCreation| will be called, allowing the binding layer to
-- store information about the edge.
--
-- For each edge an event is created, whose kind is |"edge"| and whose
-- |parameter| is a two-element array whose first entry is the edge's
-- arc in the syntactic digraph and whose second entry is the position
-- of the edge in the arc's array of syntactic edges.
--
-- @param tail           Name of the node the edge begins at.
-- @param head           Name of the node the edge ends at.
-- @param direction      Direction of the edge (e.g. |--| for an undirected edge
--                       or |->| for a directed edge from the first to the second
--                       node).
-- @param height         The option stack height, see for instance |createVertex|.
--
-- @param binding_infos These options will be stored in the |storage|
-- of the vertex at the field index by the binding.

function InterfaceToDisplay.createEdge(tail, head, direction, height, binding_infos)

  -- Setup
  local scope = InterfaceCore.topScope()
  local binding = InterfaceCore.binding

  -- Does vertex already exist?
  local h = scope.node_names[head]
  local t = scope.node_names[tail]
  assert (h and t, "attempting to create edge between nodes that are not in the graph")

  -- Create Arc object
  local arc = scope.syntactic_digraph:connect(t, h)

  -- Create Edge object
  local edge = Edge.new {
    head = h,
    tail = t,
    direction = direction,
    options = get_current_options_table(height)
  }

  -- Add to arc
  arc.syntactic_edges[#arc.syntactic_edges+1] = edge

  -- Create Event
  local e = InterfaceToDisplay.createEvent ("edge", { arc, #arc.syntactic_edges })
  edge.event = e

  -- Make part of collections
  for _,c in ipairs(edge.options.collections) do
    LookupTable.addOne(c.edges, edge)
  end

  -- Call binding
  binding.storage[edge] = binding_infos
  binding:everyEdgeCreation(edge)

end





---
-- Push an option to the stack of options.
--
-- As a graph is parsed, a stack of ``current options''
-- is created. To add something to this table, the display layers may
-- call the method |pushOption|. To pop something from this stack,
-- just set the |height| value during the next push to the position to
-- which you actually wish to push something; everything above and
-- including this position will be popped from the stack.
--
-- When an option is pushed, several additional options may also be
-- pushed, namely whenever the option has a |use| field set. These
-- additional options may, in turn, also push new options. Because of
-- this, this function returns a new stack height, representing the
-- resulting stack height.
--
-- In addition to this stack height, this function returns a Boolean
-- value indicating whether a ``main algorithm phase was set''. This
-- happens whenever a key is executed (directly or indirectly through
-- the |use| field) that selects an algorithm for the ``main''
-- algorithm phase. This information may help the caller to setup the
-- graph drawing scopes correctly.
--
-- @param key A parameter (must be a string).
-- @param value A value (can be anything). If it is a string, it will
-- be converted to whatever the key expects.
-- @param height A stack height at which to insert the key. Everything
-- above this height will be removed.
--
-- @return A new stack height
-- @return A Boolean that is |true| if the main algorithm phase was
-- set by the option or one option |use|d by it.
-- @return The newly created entry on the stack. If more entries are
-- created through the use of the |use| field, the original entry is
-- returned nevertheless.


function InterfaceToDisplay.pushOption(key, value, height)
  assert(type(key) == "string", "illegal key")

  local key_record = assert(InterfaceCore.keys[key], "unknown key")
  local main_phase_set = false

  if value == nil and key_record.default then
    value = key_record.default
  end

  -- Find out what kind of key we are pushing:

  if key_record.algorithm then
    -- Push a phase
    if type(InterfaceCore.algorithm_classes[key]) == "function" then
      -- Call the constructor function
      InterfaceCore.algorithm_classes[key] = InterfaceCore.algorithm_classes[key]()
    end

    local algorithm = InterfaceCore.algorithm_classes[key]

    assert (algorithm, "algorithm class not found")

    push_on_option_stack(phase_unique,
            { phase = value or key_record.phase, algorithm = algorithm },
            height)

    if key_record.phase == "main" then
      main_phase_set = true
    end

  elseif key_record.layer then
    -- Push a collection
    local stack = InterfaceCore.option_stack
    local scope = InterfaceCore.topScope()

    -- Get the stack above "height":
    local options = get_current_options_table(height-1)

    -- Create the collection event
    local event = InterfaceToDisplay.createEvent ("collection", key)

    -- Create collection object:
    local collection = Collection.new { kind = key, options = options, event = event }

    -- Store in collections table of current scope:
    local collections = scope.collections[key] or {}
    collections[#collections + 1] = collection
    scope.collections[key] = collections

    -- Build collection tree
    collection:registerAsChildOf(options.collections[#options.collections])

    -- Push on stack
    push_on_option_stack(collections_unique, collection, height)

  else

    -- A normal key
    push_on_option_stack(key, InterfaceCore.convert(value, InterfaceCore.keys[key].type), height)

  end

  local newly_created = InterfaceCore.option_stack[#InterfaceCore.option_stack]

  -- Now, push use keys:
  local use = key_record.use
  if key_record.use then
    local flag
    for _,u in ipairs(InterfaceCore.keys[key].use) do
      local use_k = u.key
      local use_v = u.value
      if type(use_k) == "function" then
        use_k = use_k(value)
      end
      if type(use_v) == "function" then
        use_v = use_v(value)
      end
      height, flag = InterfaceToDisplay.pushOption(use_k, use_v, height+1)
      main_phase_set = main_phase_set or flag
    end
  end

  return height, main_phase_set, newly_created
end


---
-- Push a layout on the stack of options. As long as this layout is on
-- the stack, all vertices and edges will be part of this layout. For
-- details on layouts, please see |Sublayouts|.
--
-- @param height A stack height at which to insert the key. Everything
-- above this height will be removed.

function InterfaceToDisplay.pushLayout(height)
  InterfaceToDisplay.pushOption(InterfaceCore.sublayout_kind, nil, height)
end



---
-- Creates an event and adds it to the event string of the current scope.
--
-- @param kind         Name/kind of the event.
-- @param parameters   Parameters of the event.
--
-- @return The newly pushed event
--
function InterfaceToDisplay.createEvent(kind, param)
  local scope = InterfaceCore.topScope()
  local n = #scope.events + 1
  local e = Event.new { kind = kind, parameters = param, index = n }
  scope.events[n] = e

  return e
end



---
-- This method allows you to query the table of all declared keys. It
-- contains them both as an array and also as a table index by the
-- keys's names. In particular, you can then iterate over it using
-- |ipairs| and you can  check whether a key is defined by accessing
-- the table at the key's name. Each entry of the table is the
-- original table passed to |InterfaceToAlgorithms.declare|.
--
-- @return A lookup table of all declared keys.

function InterfaceToDisplay.getDeclaredKeys()
  return InterfaceCore.keys
end




---
-- Renders the graph.
--
-- This function is called after the graph has been laid out by the
-- graph drawing algorithms. It will trigger a sequence of calls to
-- the binding layer that will, via callbacks, start rendering the
-- whole graph.
--
-- In detail, this function calls:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--local binding = InterfaceCore.binding
--
--binding:renderStart()
--render_vertices()
--render_edges()
--render_collections()
--binding:renderStop()
--\end{codeexample}
--
-- Here, the |render_...| functions are local, internal functions that are,
-- nevertheless, documented here.
--
-- @param name Returns the algorithm class that has been declared using
-- |declare| under the given name.

function InterfaceToDisplay.renderGraph()
  local scope = InterfaceCore.topScope()
  local syntactic_digraph = scope.syntactic_digraph

  local binding = InterfaceCore.binding

  binding:renderStart()
  render_vertices(syntactic_digraph.vertices)
  render_edges(syntactic_digraph.arcs)
  render_collections(scope.collections)
  binding:renderStop()
end





---
-- Render the vertices after the graph drawing algorithm has
-- finished. This function is local and internal and included only for
-- documenting the call graph.
--
-- When the graph drawing algorithm is done, the interface will start
-- rendering the vertices by calling appropriate callbacks of the
-- binding layer.
--
-- Consider the following code:
-- %
--\begin{codeexample}[code only]
--\graph [... layout] {
--  a -- b -- c -- d;
--};
--\end{codeexample}
--
-- In this case, after the graph drawing algorithm has run, the
-- present function will call:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--local binding = InterfaceCore.binding
--
--binding:renderVerticesStart()
--binding:renderVertex(vertex_a)
--binding:renderVertex(vertex_b)
--binding:renderVertex(vertex_c)
--binding:renderVertex(vertex_d)
--binding:renderVerticesStop()
--\end{codeexample}
--
-- @param vertices An array of all vertices in the syntactic digraph.

function render_vertices(vertices)
  InterfaceCore.binding:renderVerticesStart()
  for _,vertex in ipairs(vertices) do
    InterfaceCore.binding:renderVertex(vertex)
  end
  InterfaceCore.binding:renderVerticesStop()
end


---
-- Render the collections whose layer is not |0|. This local, internal
-- function is called to render the different collection kinds.
--
-- Collection kinds rendered in the order provided by the |layer|
-- field passed to |declare| during the declaration of the collection
-- kind, see also |declare_collection|. If several collection kinds
-- have the same layer, they are rendered in lexicographical ordering
-- (to ensure that they are always rendered in the same order).
--
-- Consider the following code:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--declare { key = "hyper", layer = 1 }
--\end{codeexample}
-- you can say on the \tikzname\ layer
--\begin{codeexample}[code only]
--\graph {
--  a, b, c, d;
--  { [hyper] a, b, c }
--  { [hyper] b, c, d }
--};
--\end{codeexample}
--
-- In this case, after the graph drawing algorithm has run, the
-- present function will call:
--
--\begin{codeexample}[code only, tikz syntax=false]
--local binding = InterfaceCore.binding
--
--binding:renderCollectionStartKind("hyper", 1)
--binding:renderCollection(collection_containing_abc)
--binding:renderCollection(collection_containing_bcd)
--binding:renderCollectionStopKind("hyper", 1)
--\end{codeexample}
--
-- @param collections The |collections| table of the current scope.

function render_collections(collections)
  local kinds = InterfaceCore.collection_kinds
  local binding = InterfaceCore.binding

  for i=1,#kinds do
    local kind = kinds[i].kind
    local layer = kinds[i].layer

    if layer ~= 0 then
      binding:renderCollectionStartKind(kind, layer)
      for _,c in ipairs(collections[kind] or {}) do
        binding:renderCollection(c)
      end
      binding:renderCollectionStopKind(kind, layer)
    end
  end
end


---
-- Render the syntactic edges of a graph after the graph drawing
-- algorithm has finished. This function is local and internal and included only
-- for documenting the call graph.
--
-- When the graph drawing algorithm is done, the interface will first
-- rendering the vertices using |render_vertices|, followed by calling
-- this function, which in turn calls appropriate callbacks to the
-- binding layer.
--
-- Consider the following code:
-- %
--\begin{codeexample}[code only]
-- \graph [... layout] {
--   a -- b -- c -- d;
-- };
--\end{codeexample}
--
-- In this case, after the graph drawing algorithm has run, the
-- present function will call:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- local binding = InterfaceCore.binding
--
-- binding:renderEdgesStart()
-- binding:renderEdge(edge_from_a_to_b)
-- binding:renderEdge(edge_from_b_to_c)
-- binding:renderEdge(edge_from_c_to_d)
-- binding:renderEdgesStop()
--\end{codeexample}
--
-- @param arcs The array of arcs of the syntactic digraph.

function render_edges(arcs)
  InterfaceCore.binding:renderEdgesStart()
  for _,a in ipairs(arcs) do
    for _,e in ipairs (a.syntactic_edges) do
      InterfaceCore.binding:renderEdge(e)
    end
  end
  InterfaceCore.binding:renderEdgesStop()
end


local aliases = InterfaceCore.option_aliases
local option_initial = InterfaceCore.option_initial

local option_metatable = {
  __index =
    function (t, key)
      local k = aliases[key]
      if k then
        local v = (type(k) == "string" and t[k]) or (type(k) == "function" and k(t)) or nil
        if v ~= nil then
          return v
        end
      end
      return option_initial[key]
    end
}


---
-- Get the current options table.
--
-- An option table can be accessed like a normal table; however, there
-- is a global fallback for this table. If an index is not defined,
-- the value of this index in the global fallback table is used. (This
-- reduces the overall amount of option keys that need to be stored
-- with object.)
--
-- (This function is local and internal and included only for documentation
-- purposes.)
--
-- @param height The stack height for which the option table is
-- required.
-- @param table If non |nil|, the options will be added to this
-- table.
--
-- @return The option table as described above.

function get_current_options_table (height, table)
  local stack = InterfaceCore.option_stack
  assert (height >= 0 and height <= #stack, "height value out of bounds")

  if height == InterfaceCore.option_cache_height and not table then
    return option_cache
  else
    -- Clear superfluous part of stack
    for i=#stack,height+1,-1 do
      stack[i] = nil
    end

    -- Build options table
    local cache
    if not table then
      cache = setmetatable(
        {
          algorithm_phases = setmetatable({}, InterfaceCore.option_initial.algorithm_phases),
          collections = {}
        }, option_metatable)
    else
      cache = lib.copy(table)
      cache.algorithm_phases = lib.copy(cache.algorithm_phases)
      cache.collections = lib.copy(cache.collections)
    end

    local algorithm_phases = cache.algorithm_phases
    local collections = cache.collections
    local keys = InterfaceCore.keys

    local function handle (k, v)
      if k == phase_unique then
        algorithm_phases[v.phase] = v.algorithm
        local phase_stack = v.phase .. " stack"
        local t = rawget(algorithm_phases, phase_stack)
        if not t then
          t = algorithm_phases[phase_stack]
          assert(type(t) == "table", "unknown phase")
          t = lib.copy(t)
          algorithm_phases[phase_stack] = t
        end
        t[#t + 1] = v.algorithm
      elseif k == collections_unique then
        LookupTable.addOne(collections, v)
      else
        cache[k] = v
      end
    end

    for _,s in ipairs(stack) do
      handle (s.key, s.value)
    end

    -- Cache it, if this was not added:
    if not table then
      InterfaceCore.option_cache_height = height
      option_cache                      = cache
    end

    return cache
  end
end



-- A helper function

function push_on_option_stack(key, value, height)
  local stack = InterfaceCore.option_stack

  assert (type(height) == "number" and height > 0 and height <= #stack + 1,
      "height value out of bounds")

  -- Clear superfluous part of stack
  for i=#stack,height+1,-1 do
    stack[i] = nil
  end

  stack[height] = { key = key, value = value }
  InterfaceCore.option_cache_height = nil   -- invalidate cache
end



-- Done

return InterfaceToDisplay
