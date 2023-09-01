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
-- This class provides the interface between the graph drawing system
-- and algorithms. Another class, |InterfaceToDisplay|, binds the
-- display layers (like \tikzname\ or a graph drawing editor) to the
-- graph drawing system ``from the other side''.
--
-- The functions declared here can be used by algorithms to
-- communicate with the graph drawing system, which will usually
-- forward the ``requests'' of the algorithms to the display layers in
-- some way. For instance, when you declare a new parameter, this
-- parameter will become available on the display layer.

local InterfaceToAlgorithms = {}

-- Namespace
require("pgf.gd.interface").InterfaceToAlgorithms = InterfaceToAlgorithms


-- Imports
local InterfaceCore       = require "pgf.gd.interface.InterfaceCore"
local InterfaceToDisplay  = require "pgf.gd.interface.InterfaceToDisplay"
local InterfaceToC        = require "pgf.gd.interface.InterfaceToC"

local LookupTable         = require "pgf.gd.lib.LookupTable"
local LayoutPipeline      = require "pgf.gd.control.LayoutPipeline"

local Edge                = require "pgf.gd.model.Edge"

local lib                 = require "pgf.gd.lib"

local doc                 = require "pgf.gd.doc"

-- Forwards

local declare_handlers




---
-- Adds a handler for the |declare| function. The |declare|
-- command is just a ``dispatcher'' to one of many possible
-- declaration functions. Which function is used, depends on which
-- fields are present in the table passed to |declare|. For each
-- registered handler, we call the |test| function. If it returns
-- neither |nil| nor |false|, the |handler| field of this handler is
-- called. If it returns |true|, the handler immediately
-- finishes. Otherwise, the next handler is tried.

function InterfaceToAlgorithms.addHandler(test, handler)
  table.insert(declare_handlers, 1, { test = test, handler = handler })
end



-- Local stuff

local key_metatable = {}

---
-- This function is the ``work-horse'' for declaring things. It allows
-- you to specify on the algorithmic layer that a key ``is available''
-- for use on the display layer. There is just one function for
-- handling all declarations in order to make the declarations
-- easy-to-use since you just need to import a single function:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
--\end{codeexample}
--
-- You can now use |declare| it as follows: You pass it a table
-- containing information about the to-be-declared key. The table
-- \emph{must} have a field |key| whose value is unique and must be a
-- string. If the value of |key| is, say, |"foo"|, the
-- parameter can be set on the display layer such as, say, the
-- \tikzname\ layer, using |/graph drawing/foo|. Here is a typical
-- example of how a declaration is done:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- ---
-- declare {
--   key     = "electrical charge",
--   type    = "number",
--   initial = "1.0",
--
--   summary = "The ``electrical charge'' is a property...",
--   documentation = [[...]],
--   examples = [[...]]
-- }
--\end{codeexample}
--
-- \medskip\noindent\textbf{Inlining Documentation.}
-- The three keys |summary|, |documentation| and |examples| are
-- intended for the display layer to give the users information about
-- what the key does. The |summary| should be a string that succinctly
-- describes the option. This text will typically be displayed for
-- instance as a ``tool tip'' or in an option overview. The
-- |documentation| optionally provides more information and should be
-- typeset using \TeX. The |examples| can either be a single string or
-- an array of strings. Each should be a \tikzname\ example
-- demonstrating how the key is used.
--
-- Note that you can take advantage of the Lua syntax of enclosing
-- very long multi-line strings in |[[| and |]]|. As a bonus, if the
-- summary, documentation, or an example starts and ends with a quote,
-- these two quotes will be stripped. This allows you to enclose the
-- whole multi-line string (additionally) in quotes, leading to better
-- syntax highlighting in editors.
--
-- \medskip\noindent\textbf{External Documentation.}
-- It is sometimes more desirable to put the documentation of a key
-- into an external file. First, this makes the code leaner and, thus,
-- faster to read (both for humans and for computers). Second, for C
-- code, it is quite inconvenient to have long strings inside a C
-- file. In such cases, you can use the |documentation_in| field:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- ---
-- declare {
--   key     = "electrical charge",
--   type    = "number",
--   initial = "1.0",
--   documentation_in = "some_filename"
-- }
--\end{codeexample}
--
-- The |some_filename| must be the name of a Lua file that will be
-- read ``on demand'', that is, whenever someone tries to access the
-- documentation, summary, or examples field of the key, this file
-- will be loaded using |require|. The file should then use
-- |pgf.gd.doc| to install the missing information in the keys.
--
-- \medskip\noindent\textbf{The Use Field.}
-- When you declare a key, you can provide a |use| field. If present,
-- you must set it to an array of small tables which have two fields:
-- %
-- \begin{itemize}
--   \item |key| This is the name of another key or a function.
--   \item |value| This is either a value (like a string or a number) or
--     a function or |nil|.
-- \end{itemize}
--
-- Here is an example:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- ---
-- declare {
--   key = "binary tree layout",
--   use = {
--     { key = "minimum number of children", value = 2 },
--     { key = "significant sep",            value = 12 },
--     { key = "tree layout" }
--   },
--   summary = "The |binary tree layout| places node...",
--   documentation = ...,
--   examples = ...,
-- }
--\end{codeexample}
--
-- The effect of a |use| field is the following: Whenever the key is
-- encountered on the option stack, the key is first handled
-- normally. Then, we iterate over all elements of the |use|
-- array. For each element, we perform the action as if the |key| of
-- the array had been set explicitly to the value given by the |value|
-- field. If the |value| is a function, we pass a different value to
-- the key, namely the result of applying the function to the value
-- originally passed to the original key. Here is a typical example:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- ---
-- declare {
--   key = "level sep",
--   type = "length",
--   use = {
--     { key = "level pre sep",  value = function (v) return v/2 end },
--     { key = "level post sep", value = function (v) return v/2 end }
--   },
--   summary = "..."
-- }
--\end{codeexample}
--
-- Just like the value, the key itself can also be a function. In this
-- case, the to-be-used key is also computed by applying the function
-- to the value passed to the original key.
--
-- As mentioned at the beginning, |declare| is a work-horse that will call
-- different internal functions depending on whether you declare a
-- parameter key or a new algorithm or a collection kind. Which kind
-- of declaration is being done is detected by the presence of certain
-- fields in the table passed to |t|. The different kind of
-- possible declarations are documented in the |declare_...|
-- functions. Note that these functions are internal and cannot be
-- called from outside; you must use the |declare| function.
--
-- @param t A table contain the field |key| and other fields as
-- described.

function InterfaceToAlgorithms.declare (t)
  local keys = InterfaceCore.keys

  -- Sanity check:
  assert (type(t.key) == "string" and t.key ~= "", "parameter key may not be the empty string")
  if keys[t.key] or t.keys == "algorithm_phases" then
    error("parameter '" .. t.key .. "' already declared")
  end

  for _,h in ipairs (declare_handlers) do
    if h.test(t) then
      if h.handler(t) then
        break
      end
    end
  end

  -- Attach metatable:
  setmetatable (t, key_metatable)

  -- Set!
  keys[t.key]     = t
  keys[#keys + 1] = t
end


function key_metatable.__index (key_table, what)
  if what == "documentation" or what == "summary" or what == "examples" then
    local doc = rawget(key_table,"documentation_in")
    if doc then
      require (doc)
      return rawget(key_table, what)
    end
  end
end



---
-- This function is called by |declare| for ``normal parameter keys'',
-- which are all keys for which no special field like |algorithm| or
-- |layer| is declared. You write
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- ---
-- declare {
--   key     = "electrical charge",
--   type    = "number",
--   initial = "1.0",
--
--   summary = "The ``electrical charge'' is a property...",
--   documentation = [[...]],
--   examples = [[...]]
-- }
--\end{codeexample}
--
-- When an author writes |my node[electrical charge=5-3]| in the
-- description of her graph, the object |vertex| corresponding to the
-- node |my node| will have a field |options| attached to it with
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--vertex.options["electrical charge"] == 2
--\end{codeexample}
--
-- The |type| field does not refer to Lua types. Rather, these types are
-- sensible types for graph drawing and they are mapped by the higher
-- layers to Lua types. In detail, the following types are available:
-- %
-- \begin{itemize}
--   \item |number| A dimensionless number. Will be mapped to a normal
--     Lua |number|. So, when the author writes |foo=5*2|, the |foo| key
--     of the |options| field of the corresponding object will be set to
--     |10.0|.
--   \item |length| A ``dimension'' in the sense of \TeX\ (a number with
--     a dimension like |cm| attached to it). It is the job of the display
--     layer to map this to a number in ``\TeX\ points'', that is, to a
--     multiple of $1/72.27$th of an inch.
--   \item |time| A ``time'' in the sense of |\pgfparsetime|. Examples
--     are |6s| or |0.1min| or |6000ms|, all of which will map to |6|.
--   \item |string| Some text. Will be mapped to a Lua |string|.
--   \item |canvas coordinate| A position on the canvas. Will be mapped
--     to a |model.Coordinate|.
--   \item |boolean| A Boolean value.
--   \item |raw| Some to-be-executed Lua text.
--   \item |direction| Normally, an angle; however,
--     the special values of |down|, |up|, |left|, |right| as well as the
--     directions |north|, |north west|, and so on are also legal on the
--     display layer. All of them will be mapped to a number. Furthermore,
--     a vertical bar (\verb!|!) will be mapped to |-90| and a minus sign
--     (|-|) will be mapped to |0|.
--   \item |hidden| A key of this type ``cannot be set'', that is,
--     users cannot set this key at all. However algorithms can still read
--     this key and, through the use of |alias|, can use the key as a
--     handle to another key.
--   \item |user value| The key stores a Lua user value (userdata). Such
--     keys can only be set from C since user values cannot be created in
--     Lua (let alone in \tikzname).
-- \end{itemize}
--
-- If the |type| field is missing, it is automatically set to
-- |"string"|.
--
-- A parameter can have an |initial| value. This value will be used
-- whenever the parameter has not been set explicitly for an object.
--
-- A parameter can have a |default| value. This value will be used as
-- the parameter value whenever the parameter is explicitly set, but
-- no value is provided. For a key of type |"boolean"|, if no
-- |default| is provided, |"true"| will be used automatically.
--
-- A parameter can have an |alias| field. This field must be set to
-- the name of another key or to a function. Whenever you access the
-- current key and this key is not set, the |alias| key is tried
-- instead. If it is  set, its value will be returned (if the |alias|
-- key has itself an  alias set, this is tried recursively). If the
-- alias is not set either and neither does it have an initial value,
-- the |initial| value is used. Note that in case the alias has its
-- |initial| field set, the |initial| value of the current key will
-- never be used.
--
-- The main purpose of the current key is to allow algorithms to
-- introduce their own terminology for keys while still having access
-- to the standard keys. For instance, the |OptimalHierarchyLayout|
-- class uses the name |layerDistance| for what would be called
-- |level distance| in the rest of the graph drawing system. In this
-- case, we can declare the |layerDistance| key as follows:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- declare {
--   key     = "layerDistance",
--   type    = "length",
--   alias   = "level distance"
-- }
--\end{codeexample}
--
-- Inside the algorithm, we can write |...options.layerDistance| and
-- will get the current value of the |level distance| unless the
-- |layerDistance| has been set explicitly. Indeed, we might set the
-- |type| to |hidden| to ensure that \emph{only} the |level distance|
-- can and must set to set the layerDistance.
--
-- Note that there is a difference between |alias| and the |use|
-- field: Suppose we write
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- declare {
--   key     = "layerDistance",
--   type    = "length",
--   use     = {
--     { key = "level distance", value = lib.id }
--   }
-- }
--\end{codeexample}
--
-- Here, when you say |layerDistance=1cm|, the |level distance| itself
-- will be modified. When the |level distance| is set, however, the
-- |layerDistance| will not be modified.
--
-- If the alias is a function, it will be called with the option table
-- as its parameter. You can thus say things like
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- declare {
--   key     = "layerDistance",
--   type    = "length",
--   alias   = function (option)
--               return option["layer pre dist"] + option["layer post dist"]
--             end
-- }
--\end{codeexample}
--
-- As a special courtesy to C code, you can also set the key
-- |alias_function_string|, which allows you to put the function into
-- a string that is read using |loadstring|.
--
-- (You cannot call this function directly, it is included for
-- documentation purposes only.)
--
-- @param t The table originally passed to |declare|.

local function declare_parameter (t)

  t.type = t.type or "string"

  if t.type == "boolean" and t.default == nil then
    t.default = true
  end

  -- Normal key
  assert (type(t.type) == "string", "key type must be a string")

  -- Declare via the hub:
  if t.type ~= "hidden" then
    InterfaceCore.binding:declareCallback(t)

    -- Handle initials:
    if t.initial then
      InterfaceCore.option_initial[t.key] = InterfaceCore.convert(t.initial, t.type)
    end
  end

  if t.alias_function_string and not t.alias then
    local count = 0
    t.alias = load (
      function ()
        count = count + 1
        if count == 1 then
          return "return "
        elseif count == 2 then
          return t.alias_function_string
        else
          return nil
        end
      end)()
  end

  if t.alias then
    assert (type(t.alias) == "string" or type(t.alias == "function"), "alias must be a string or a function")
    InterfaceCore.option_aliases[t.key] = t.alias
  end

  return true
end




---
-- This function is called by |declare| for ``algorithm
-- keys''. These keys are normally used without a value as in just
-- |\graph[tree layout]|, but you can optionally pass a value to
-- them. In this case, this value must be the name of a \emph{phase}
-- and the algorithm of this phase will be set (and not the
-- default phase of the key), see the description of phases below for
-- details.
--
-- Algorithm keys are detected by the presence of the field |algorithm|
-- in the table |t| passed to |declare|. Here is an example of how it
-- is used:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- local ReingoldTilford1981 = {}
--
-- ---
-- declare {
--   key       = "tree layout",
--   algorithm = ReingoldTilford1981,
--
--   preconditions = {
--     connected = true,
--     tree      = true
--   },
--
--   postconditions = {
--     upward_oriented = true
--   },
--
--   summary = "The Reingold--Tilford method is...",
--   documentation = ...,
--   examples = ...,
-- }
--
-- function ReingoldTilford1981:run()
--   ...
-- end
--\end{codeexample}
--
-- The |algorithm| field expects either a table or a string as
-- value. If you provide a string, then |require| will be applied to
-- this string to obtain the table; however, this will happen only
-- when the key is actually used for the first time. This means that
-- you can declare (numerous) algorithms in a library without these
-- algorithms actually being loaded until they are needed.
--
-- Independently of how the table is obtained, it will be ``upgraded''
-- to a class by setting its |__index| field and installing a static
-- |new| function (which takes a table of initial values as
-- argument). Both these settings will only be done if they have not
-- yet been performed.
--
-- Next, you can specify the fields |preconditions| and
-- |postconditions|. The preconditions are a table that tell the graph
-- drawing engine what kind of graphs your algorithm expects. If the
-- input graph is not of this kind, it will be automatically
-- transformed to meet this condition. Similarly, the postconditions
-- tell the engine about properties of your graph after the algorithm
-- has run. Again, additional transformations may be performed.
--
-- You can also specify the field |phase|. This tells the graph
-- drawing engine which ``phase'' of the graph drawing process your
-- option applies to. Each time you select an algorithm later on
-- through use of the algorithm's key, the algorithm for this phase
-- will be set; algorithms of other phases will not be changed.
-- For instance, when an algorithm is part of the spanning tree
-- computation, its phase will be |"spanning tree computation"| and
-- using its key does not change the main algorithm, but only the
-- algorithm used during the computation of a spanning tree for the
-- current graph (in case this is needed by the main algorithm). In
-- case the |phase| field is missing, the phase |main| is used. Thus,
-- when no phase field is given, the key will change the main
-- algorithm used to draw the graph.
--
-- Later on, the algorithm set for the current phase can be accessed
-- through the special |algorithm_phases| field of |options|
-- tables. The |algorithm_phases| table will contain two fields for each
-- phase for which some algorithm has been set: One field is the name
-- of the phase and its value will be the most recently set algorithm
-- (class) set for this phase. The other field is the name of the
-- phase followed by |" stack"|. It will contain an array of all
-- algorithm classes that have been set for this key with the most
-- recently at the end.
--
-- The following example shows the declaration of an algorithm that is
-- the default for the phase |"spanning tree computation"|:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- ---
-- declare {
--   key = "breadth first spanning tree",
--   algorithm = {
--     run =
--       function (self)
--         return SpanningTreeComputation.computeSpanningTree(self.ugraph, false, self.events)
--       end
--   },
--   phase = "spanning tree computation",
--   phase_default = true,
--   summary = ...
-- }
--\end{codeexample}
--
-- The algorithm is called as follows during a run of the main
-- algorithms:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
-- local graph = ... -- the graph object
-- local spanning_algorithm_class = graph.options.algorithm_phases["spanning tree computation"]
-- local spanning_algorithm =
--   spanning_algorithm_class.new{
--     ugraph = ugraph,
--     events = scope.events
--   }
-- local spanning_tree = spanning_algorithm:run()
--\end{codeexample}
--
-- If you set the |phase_default| field of |t| to |true|, the algorithm will
-- be installed as the default algorithm for the phase. This can be
-- done only once per phase. Furthermore, for such a default algorithm
-- the |algorithm| key must be table, it may not be a string (in other
-- words, all default algorithms are loaded immediately). Accessing
-- the |algorithm_phases| table for a phase for which no algorithm has
-- been set will result in the default algorithm and the phase stack
-- will also contain this algorithm; otherwise the phase stack will be empty.
--
-- (You cannot call this function directly, it is included for
-- documentation purposes only.)
--
-- @param t The table originally passed to |declare|.

local function declare_algorithm (t)
  -- Algorithm declaration!
  assert(type(t.algorithm) == "table" or type(t.algorithm) == "string")

  t.phase = t.phase or "main"

  local function make_class ()
    local class

    if type(t.algorithm) == "table" then
      class = lib.class(t.algorithm)
    else
      class = lib.class(require(t.algorithm))
    end

    -- Now, save pre- and postconditions
    class.preconditions  = t.preconditions or {}
    class.postconditions = t.postconditions or {}

    -- Save phase
    class.phase          = t.phase

    -- Compatibility
    class.old_graph_model = t.old_graph_model

    return class
  end

  -- Store this:
  local store_me
  if type(t.algorithm) == "table" then
    store_me = make_class()
  else
    store_me = make_class
  end

  -- Save in the algorithm_classes table:
  InterfaceCore.algorithm_classes[t.key] = store_me

  assert(t.type == nil, "type may not be set for an algorithm key")
  t.type = "string"

  -- Install!
  InterfaceCore.binding:declareCallback(t)

  if t.phase_default then
    assert (not InterfaceCore.option_initial.algorithm_phases[t.phase],
        "default algorithm for phase already set")
    assert (type(store_me) == "table",
        "default algorithms must be loaded immediately")
    InterfaceCore.option_initial.algorithm_phases[t.phase] = store_me
    InterfaceCore.option_initial.algorithm_phases[t.phase .. " stack"] = { store_me }
  else
    InterfaceCore.option_initial.algorithm_phases[t.phase .. " stack"] = {
      dummy = true -- Remove once Lua Link Bug is fixed
    }
  end

  return true
end




---
-- This function is called by |declare| for ``collection kinds''. They
-- are detected by the presence of the field |layer|
-- in the table |t| passed to |declare|. See the class |Collection|
-- for details on what a collection and a collection kind is.
--
-- The |key| field of the table |t| passed to this function is both
-- the name of the to-be-declared collection kind as well as the key
-- that is used on the display layer to indicate that a node or edge
-- belongs to a collection.
--
-- \medskip
-- \noindent\textbf{The Display Layer.}
-- Let us first have a look at what happens on the display layer:
-- A key |t.key| is setup on the display layer that, when used inside
-- a graph drawing scope, starts a new collection of the specified
-- kind. ``Starts'' means that all nodes and edges mentioned in the
-- rest of the current option scope will belong to a new collection
-- of kind |t.key|.
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--declare { key = "hyper", layer = 1 }
--\end{codeexample}
-- %
-- you can say on the \tikzname\ layer
-- %
--\begin{codeexample}[code only]
-- \graph {
--   a, b, c, d;
--   { [hyper] a, b, c }
--   { [hyper] b, c, d }
-- };
--\end{codeexample}
--
-- In this case, the nodes |a|, |b|, |c| will belong to a collection of
-- kind |hyper|. The nodes |b|, |c|, and |d| will (also) belong to
-- another collection of the same kind |hyper|. You can nest
-- collections; in this case, nodes will belong to several
-- collections.
--
-- The effect of declaring a collection kind on the algorithm layer
-- it, first of all, that |scope.collections| will have a field named
-- by the collection kind. This field will store an array that
-- contains all collections that were declared as part of the
-- graph. For instance, |collections.hyper| will contain all
-- hyperedges, each of which is a table with the following fields: The
-- |vertices| and |edges| fields each contain arrays of all objects
-- being part of the collection. The |sub| field is an array of
-- ``subcollections'', that is, all collections that were started
-- inside another collection. (For the collection kinds |hyper| and
-- |same layer| this makes no sense, but subgraphs could, for instance,
-- be nested.)
--
-- \medskip
-- \noindent\textbf{Rendering of Collections.}
-- For some kinds of collections, it makes sense to \emph{render} them,
-- but only after the graph drawing algorithm has run. For this
-- purpose, the binding layer will use a callback for each collection
-- kind and each collection, see the |Binding| class for details.
-- Suppose, for instance, you would
-- like hyperedges to be rendered. In this case, a graph drawing
-- algorithm should iterate over all collections of type |hyper| and
-- compute some hints on how to render the hyperedge and store this
-- information in the |generated_options| table of the hyperedge. Then,
-- the binding layer will ask the display layer to run some some code
-- that is able to read key--value pairs passed to
-- it (which are the key--value pairs of the |generated_options| table)
-- and use this information to nicely draw the hyperedge.
--
-- The number |t.layer| determines in which order the different
-- collection kinds are rendered.
--
-- The last parameter, the layer number, is used to specify the order
-- in which the different collection kinds are rendered. The higher the
-- number, the later the collection will be rendered. Thus, if there is
-- a collection kind with layer number 10 and another with layer number
-- 20, all collections of the first kind will be rendered first,
-- followed by all collections of the second kind.
--
-- Collections whose layer kinds are non-negative get rendered
-- \emph{after} the nodes and edges have already been rendered. In
-- contrast, collections with a negative layer number get shown
-- ``below'' the nodes and edges.
--
-- (You cannot call this function directly, it is included for
-- documentation purposes only.)
--
-- @param t The table originally passed to |declare|.

local function declare_collection_kind (t)
  assert (type(t.layer) == "number", "layer must be a number")

  local layer = t.layer
  local kind  = t.key
  local kinds = InterfaceCore.collection_kinds
  local new_entry = { kind = kind, layer = layer }

  -- Insert into table part:
  kinds[kind] = new_entry

  -- Insert into array part:
  local found
  for i=1,#kinds do
    if kinds[i].layer > layer or (kinds[i].layer == layer and kinds[i].kind > kind) then
      table.insert(kinds, i, new_entry)
      return
    end
  end

  kinds[#kinds+1] = new_entry

  -- Bind
  InterfaceCore.binding:declareCallback(t)

  return true
end



-- Build in handlers:

declare_handlers = {
  { test = function (t) return t.algorithm_written_in_c end, handler = InterfaceToC.declare_algorithm_written_in_c },
  { test = function (t) return t.algorithm end, handler = declare_algorithm },
  { test = function (t) return t.layer end, handler = declare_collection_kind },
  { test = function (t) return true end, handler = declare_parameter }
}








---
-- Finds a node by its name. This method should be used by algorithms
-- for which a node name is specified in some option and, thus, needs
-- to be converted to a vertex object during a run of the algorithm.
--
-- @param name A node name
--
-- @return The vertex of the given name in the syntactic digraph or
-- |nil|.

function InterfaceToAlgorithms.findVertexByName(name)
  return InterfaceCore.topScope().node_names[name]
end





-- Helper function
local function add_to_collections(collection,where,what)
  if collection then
    LookupTable.addOne(collection[where],what)
    add_to_collections(collection.parent,where,what)
  end
end

local unique_count = 1

---
-- Generate a new vertex in the syntactic digraph. Calling this method
-- allows algorithms to create vertices that are not present in the
-- original input graph. Using the graph drawing coroutine, this
-- function will pass back control to the display layer in order to
-- render the vertex and, thereby, create precise size information
-- about it.
--
-- Note that creating new vertices in the syntactic digraph while the
-- algorithm is already running is a bit at odds with the notion of
-- treating graph drawing as a series of graph transformations: For
-- instance, when a new vertex is created, the graph will (at least
-- temporarily) no longer be connected; even though an algorithm may
-- have requested that it should only be fed connected
-- graphs. Likewise, more complicated requirements like insisting on
-- the graph being a tree also cannot be met.
--
-- For these reasons, the following happens, when a new vertex is
-- created using the function:
-- %
-- \begin{enumerate}
--   \item The vertex is added to the syntactic digraph.
--   \item It is added to all layouts on the current layout stack. When
--     a graph drawing algorithm is run, it is not necessarily run on the
--     original syntactic digraph. Rather, a sequence / stack of nested
--     layouts may currently
--     be processed and the vertex is added to all of them.
--   \item The vertex is added to both the |digraph| and the |ugraph| of
--    the current algorithm.
-- \end{enumerate}
--
-- @param algorithm An algorithm for whose syntactic digraph the node
-- should be added
-- @param init  A table of initial values for the node that is passed
-- to |Binding:createVertex|, see that function for details.
--
-- @return The newly created node
--
function InterfaceToAlgorithms.createVertex(algorithm, init)

  -- Setup
  local scope = InterfaceCore.topScope()
  local binding = InterfaceCore.binding

  -- Setup node
  if not init.name then
    init.name = "internal@gd@node@" .. unique_count
    unique_count = unique_count + 1
  end

  -- Does vertex already exist?
  assert (not scope.node_names[name], "node already created")

  if not init.shape or init.shape == "none" then
    init.shape = "rectangle"
  end

  -- Call binding
  binding:createVertex(init)

  local v = assert(scope.node_names[init.name], "internal node creation failed")

  -- Add vertex to the algorithm's digraph and ugraph
  algorithm.syntactic_component:add {v}
  algorithm.digraph:add {v}
  algorithm.ugraph:add {v}

  -- Compute bounding boxes:
  LayoutPipeline.prepareBoundingBoxes(algorithm.rotation_info, algorithm.adjusted_bb, algorithm.digraph, {v})

  -- Add the node to the layout stack:
  add_to_collections(algorithm.layout, "vertices", v)

  algorithm.layout_graph:add { v }

  return v
end



---
-- Generate a new edge in the syntactic digraph. This method is quite
-- similar to |createVertex| and has the same effects with respect to
-- the edge: The edge is added to the syntactic digraph and also to
-- all layouts on the layout stack. Furthermore, appropriate edges are
-- added to the |digraph| and the |ugraph| of the algorithm currently
-- running.
--
-- @param algorithm An algorithm for whose syntactic digraph the node should be added
-- @param tail A syntactic tail vertex
-- @param head A syntactic head vertex
-- @param init A table of initial values for the edge.
--
-- The following fields are useful for |init|:
-- %
-- \begin{itemize}
--   \item |init.direction| If present, a direction for the edge. Defaults to "--".
--   \item |init.options| If present, some options for the edge.
--   \item |init.generated_options| A table that is passed back to the
--     display layer as a list of key-value pairs in the syntax of
--     |declare_parameter|.
-- \end{itemize}

function InterfaceToAlgorithms.createEdge(algorithm, tail, head, init)

  init = init or {}

  -- Setup
  local scope = InterfaceCore.topScope()
  local binding = InterfaceCore.binding
  local syntactic_digraph   = algorithm.layout_graph
  local syntactic_component = algorithm.syntactic_component

  assert (syntactic_digraph:contains(tail) and
      syntactic_digraph:contains(head),
      "attempting to create edge between nodes that are not in the syntactic digraph")

  local arc = syntactic_digraph:connect(tail, head)

  local edge = Edge.new {
    head = head,
    tail = tail,
    direction = init.direction or "--",
    options = init.options or algorithm.layout.options,
    path = init.path,
    generated_options = init.generated_options
  }

  -- Add to arc
  arc.syntactic_edges[#arc.syntactic_edges+1] = edge

  local s_arc = syntactic_component:connect(tail, head)
  s_arc.syntactic_edges = arc.syntactic_edges

  -- Create Event
  local e = InterfaceToDisplay.createEvent ("edge", { arc, #arc.syntactic_edges })
  edge.event = e

  -- Make part of collections
  for _,c in ipairs(edge.options.collections) do
    LookupTable.addOne(c.edges, edge)
  end

  -- Call binding
  binding.storage[edge] = {}
  binding:everyEdgeCreation(edge)

  -- Add edge to digraph and ugraph
  local direction = edge.direction
  if direction == "->" then
    algorithm.digraph:connect(tail, head)
  elseif direction == "<-" then
    algorithm.digraph:connect(head, tail)
  elseif direction == "--" or direction == "<->" then
    algorithm.digraph:connect(tail, head)
    algorithm.digraph:connect(head, tail)
  end
  algorithm.ugraph:connect(tail, head)
  algorithm.ugraph:connect(head, tail)

  -- Add edge to layouts
  add_to_collections(algorithm.layout, "edges", edge)

end





-- Done

return InterfaceToAlgorithms
