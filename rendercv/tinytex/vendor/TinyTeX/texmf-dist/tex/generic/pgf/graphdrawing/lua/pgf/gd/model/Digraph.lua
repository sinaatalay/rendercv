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
-- Each |Digraph| instance models a \emph{directed, simple}
-- graph. ``Directed'' means that all edges ``point'' from a head node
-- to a tail node. ``Simple'' means that between any nodes there can be
-- (at most) one edge. Since these properties are a bit at odds with
-- the normal behavior of ``nodes'' and ``edges'' in \tikzname,
-- different names are used for them inside the |model| namespace:
-- The class modeling  ``edges'' is actually called |Arc| to stress
-- that an arc has a specific ``start'' (the tail) and a specific
-- ``end'' (the head). The class modeling ``nodes'' is actually called
-- |Vertex|, just to stress that this is not a direct model of a
-- \tikzname\ |node|, but can represent a arbitrary vertex of a graph,
-- independently of whether it is an actual |node| in \tikzname.
--
-- \medskip
-- \noindent\emph{Time Bounds.}
-- Since digraphs are constantly created and modified inside the graph
-- drawing engine, some care was taken to ensure that all operations
-- work as quickly as possible. In particular:
-- %
-- \begin{itemize}
--   \item Adding an array of $k$ vertices using the |add| method needs
--     time $O(k)$.
--   \item Adding an arc between two vertices needs time $O(1)$.
--   \item Accessing both the |vertices| and the |arcs| fields takes time
--     $O(1)$, provided only the above operations are used.
-- \end{itemize}
-- %
-- Deleting vertices and arcs takes more time:
-- %
-- \begin{itemize}
-- \item Deleting the vertices given in an array of $k$ vertices from a
--   graph with $n$ vertices takes time $O(\max\{n,c\})$ where $c$ is the
--   number of arcs between the to-be-deleted nodes and the remaining
--   nodes. Note that this time bound in independent of~$k$. In
--   particular, it will be much faster to delete many vertices by once
--   calling the |remove| function instead of calling it repeatedly.
-- \item Deleting an arc takes time $O(t_o+h_i)$ where $t_o$ is the
--   number of outgoing arcs at the arc's tail and $h_i$ is the number
--   of incoming arcs at the arc's head. After a call to |disconnect|,
--   the next use of the |arcs| field will take time $O(|V| + |E|)$,
--   while subsequent accesses take time $O(1)$ -- till the
--   next use of |disconnect|. This means that once you start deleting
--   arcs using |disconnect|, you should perform as many additional
--   |disconnect|s as possible before accessing |arcs| one more.
-- \end{itemize}
--
-- \medskip
-- \noindent\emph{Stability.} The |vertices| field and the array
-- returned by |Digraph:incoming| and |Digraph:outgoing| are
-- \emph{stable} in the following sense: The ordering of the elements
-- when you use |ipairs| on the will be the ordering in which the
-- vertices or arcs were added to the graph. Even when you remove a
-- vertex or an arc, the ordering of the remaining elements stays the
-- same.
--
-- @field vertices This array contains the vertices that are part of
-- the digraph. Internally, this array
-- is an object of type |LookupTable|, but you can mostly treat it as
-- if it were an array. In particular, you can iterate over its
-- elements using |ipairs|, but you may not modify the array; use the
-- |add| and |remove| methods, instead.
--
-- \begin{codeexample}[code only, tikz syntax=false]
-- local g = Digraph.new {}
--
-- g:add { v1, v2 } -- Add vertices v1 and v2
-- g:remove { v2 }  -- Get rid of v2.
--
-- assert (g:contains(v1))
-- assert (not g:contains(v2))
-- \end{codeexample}
--
-- It is important to note that although each digraph stores a
-- |vertices| array, the elements in this array are not exclusive to
-- the digraph: A vertex can be an element of any number of
-- digraphs. Whether or not a vertex is an element of digraph is not
-- stored in the vertex, only in the |vertices| array of the
-- digraph. To test whether a digraph contains a specific node, use the
-- |contains| method, which takes time $O(1)$ to perform the test (this
-- is because, as mentioned earlier, the |vertices| array is actually a
-- |LookupTable| and for each vertex |v| the field |vertices[v]| will
-- be true if, and only if, |v| is an element of the |vertices| array).
--
-- Do not use |pairs(g.vertices)| because this may cause your graph
-- drawing algorithm to produce different outputs on different runs.
--
-- A slightly annoying effect of vertices being able to belong to
-- several graphs at the same time is that the set of arcs incident to
-- a vertex is not a property of the vertex, but rather of the
-- graph. In other words, to get a list of all arcs whose tail is a
-- given vertex |v|, you cannot say something like |v.outgoings| or
-- perhaps |v:getOutgoings()|. Rather, you have to say |g:outgoing(v)|
-- to get this list:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--for _,a in ipairs(g:outgoing(v)) do  -- g is a Digraph object.
--  pgf.debug ("There is an arc leaving " .. tostring(v) ..
--             " heading to " .. tostring(a.head))
--end
--\end{codeexample}
-- %
-- Naturally, there is also a method |g:incoming()|.
--
-- To iterate over all arcs of a graph you can say:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--for _,v in ipairs(g.vertices) do
--  for _,a in ipairs(g:outgoing(v)) do
--   ...
--  end
--end
--\end{codeexample}
--
-- However, it will often be more convenient and, in case the there
-- are far less arcs than vertices, also faster to write
--
--\begin{codeexample}[code only, tikz syntax=false]
--for _,a in ipairs(g.arcs) do
--  ...
--end
--\end{codeexample}
--
-- @field arcs For any two vertices |t| and |h| of a graph, there may
--   or may not be
--   an arc from |t| to |h|. If this is the case, there is an |Arc|
--   object that represents this arc. Note that, since |Digraph|s are
--   always simple graphs, there can be at most one such object for every
--   pair of vertices. However, you can store any information you like for
--   an |Arc| through a |Storage|, see the |Storage| class for
--   details. Each |Arc| for an edge of the syntactic digraph stores
--   an array called |syntactic_edges| of all the multiple edges that
--   are present in the user's input.
--
--   Unlike vertices, the arc objects of a graph are always local to a
--   graph; an |Arc| object can never be part of two digraphs at the same
--   time. For this reason, while for vertices it makes sense to create
--   |Vertex| objects independently of any |Digraph| objects, it is not
--   possible to instantiate an |Arc| directly: only the |Digraph| method
--   |connect| is allowed to create new |Arc| objects and it will return
--   any existing arcs instead of creating new ones, if there is already
--   an arc present between two nodes.
--
--   The |arcs| field of a digraph contains a |LookupTable| of all arc
--   objects present in the |Digraph|. Although you can access this field
--   normally and use it in |ipairs| to iterate over all arcs of a graph,
--   note that this array is actually ``reconstructed lazily'' whenever
--   an arc is deleted from the graph. What happens is the following: As
--   long as you just add arcs to a graph, the |arcs| array gets updated
--   normally. However, when you remove an arc from a graph, the arc does
--   not get removed from the |arcs| array (which would be an expensive
--   operation). Instead, the |arcs| array is invalidated (internally set
--   to |nil|), allowing us to perform a |disconnect| in time
--   $O(1)$. The |arcs| array is then ignored until the next time it is
--   accessed, for instance when a user says |ipairs(g.arcs)|. At this
--   point, the |arcs| array is reconstructed by adding all arcs of all
--   nodes to it.
--
--   The bottom line of the behavior of the |arcs| field is that (a) the
--   ordering of the elements may change abruptly whenever you remove an
--   arc from a graph and (b) performing $k$ |disconnect| operations in
--   sequence takes time $O(k)$, provided you do not access the |arcs|
--   field between calls.
--
-- @field syntactic_digraph is a reference to the syntactic digraph
--    from which this graph stems ultimately. This may be a cyclic
--    reference to the graph itself.
-- @field options If present, it will be a table storing
-- the options set for the syntactic digraph.
--
local Digraph = {}

local function recalc_arcs (digraph)
  local arcs = {}
  local vertices = digraph.vertices
  for i=1,#vertices do
    local out = vertices[i].outgoings[digraph]
    for j=1,#out do
      arcs[#arcs + 1] = out[j]
    end
  end
  digraph.arcs = arcs
  return arcs
end

Digraph.__index =
  function (t, k)
    if k == "arcs" then
      return recalc_arcs(t)
    else
      return rawget(Digraph,k)
    end
  end



-- Namespace
require("pgf.gd.model").Digraph = Digraph

-- Imports
local Arc         = require "pgf.gd.model.Arc"
local LookupTable = require "pgf.gd.lib.LookupTable"
local Vertex      = require "pgf.gd.model.Vertex"





---
-- Graphs are created using the |new| method, which takes a table of
-- |initial| values as input (like most |new| methods in the graph
-- drawing system). It is permissible that this table of initial values
-- has a |vertices| field, in which case this array will be copied. In
-- contrast, an |arcs| field in the table will be ignored -- newly
-- created graphs always have an empty arcs set. This means that
-- writing |Digraph.new(g)| where |g| is a graph creates a new graph
-- whose vertex set is the same as |g|'s, but where there are no edges:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--local g = Digraph.new {}
--g:add { v1, v2, v3 }
--g:connect (v1, v2)
--
--local h = Digraph.new (g)
--assert (h:contains(v1))
--assert (not h:arc(v1, v2))
--\end{codeexample}
--
-- To completely copy a graph, including all arcs, you have to write:
--\begin{codeexample}[code only, tikz syntax=false]
--local h = Digraph.new (g)
--for _,a in ipairs(g.arcs) do h:connect(a.tail, a.head) end
--\end{codeexample}
--
-- This operation takes time $O(1)$.
--
-- @param initial A table of initial values. It is permissible that
--                this array contains a |vertices| field. In this
--                case, this field must be an array and its entries
--                must be nodes, which will be inserted. If initial
--                has an |arcs| field, this field will be ignored.
--                The table must contain a field |syntactic_digraph|,
--                which should normally be the syntactic digraph of
--                the graph, but may also be the string |"self"|, in
--                which case it will be set to the newly created
--                (syntactic) digraph.
-- @return A newly-allocated digraph.
--
function Digraph.new(initial)
  local digraph = {}
  setmetatable(digraph, Digraph)

  if initial then
    for k,v in pairs(initial or {}) do
      digraph [k] = v
    end
  end

  local vertices = digraph.vertices
  digraph.vertices = {}
  digraph.arcs = {}

  if vertices then
    digraph:add(vertices)
  end
  return digraph
end


--- Add vertices to a digraph.
--
-- This operation takes time $O(|\verb!array!|)$.
--
-- @param array An array of to-be-added vertices.
--
function Digraph:add(array)
  local vertices = self.vertices
  for i=1,#array do
    local v = array[i]
    if not vertices[v] then
      vertices[v] = true
      vertices[#vertices + 1] = v
      v.incomings[self] = {}
      v.outgoings[self] = {}
    end
  end
end


--- Remove vertices from a digraph.
--
-- This operation removes an array of vertices from a graph. The
-- operation takes time linear in the number of vertices, regardless of
-- how many vertices are to be removed. Thus, it will be (much) faster
-- to delete many vertices by first compiling them in an array and to
-- then delete them using one call to this method.
--
-- This operation takes time $O(\max\{|\verb!array!|, |\verb!self.vertices!|\})$.
--
-- @param array The to-be-removed vertices.
--
function Digraph:remove(array)
  local vertices = self.vertices

  -- Mark all to-be-deleted nodes
  for i=1,#array do
    local v = array[i]
    assert(vertices[v], "to-be-deleted node is not in graph")
    vertices[v] = false
  end

  -- Disconnect them
  for i=1,#array do
    self:disconnect(array[i])
  end

  LookupTable.remove(self.vertices, array)
end



--- Test, whether a graph contains a given vertex.
--
-- This operation takes time $O(1)$.
--
-- @param v The vertex to be tested.
--
function Digraph:contains(v)
  return v and self.vertices[v] == true
end




---
-- Returns the arc between two nodes, provided it exists. Otherwise,
-- |nil| is returned.
--
-- This operation takes time $O(1)$.
--
-- @param tail The tail vertex
-- @param head The head vertex
--
-- @return The arc object connecting them
--
function Digraph:arc(tail, head)
  local out = tail.outgoings[self]
  if out then
    return out[head]
  end
end



---
-- Returns an array containing the outgoing arcs of a vertex. You may
-- only iterate over his array using ipairs, not using pairs.
--
-- This operation takes time $O(1)$.
--
-- @param v The vertex
--
-- @return An array of all outgoing arcs of this vertex (all arcs
-- whose tail is the vertex)
--
function Digraph:outgoing(v)
  return assert(v.outgoings[self], "vertex not in graph")
end



---
-- Sorts the array of outgoing arcs of a vertex. This allows you to
-- later iterate over the outgoing arcs in a specific order.
--
-- This operation takes time $O(|\verb!outgoing!| \log |\verb!outgoings!|)$.
--
-- @param v The vertex
-- @param f A comparison function that is passed to |table.sort|
--
function Digraph:sortOutgoing(v, f)
  table.sort(assert(v.outgoings[self], "vertex not in graph"), f)
end


---
-- Reorders the array of outgoing arcs of a vertex. The parameter array
-- \emph{must} contain the same set of vertices as the outgoing array,
-- but possibly in a different order.
--
-- This operation takes time $O(|\verb!outgoing!|)$, where |outgoing|
-- is the array of |v|'s outgoing arcs in |self|.
--
-- @param v The vertex
-- @param vertices An array containing the outgoing vertices in some order.
--
function Digraph:orderOutgoing(v, vertices)
  local outgoing = assert (v.outgoings[self], "vertex not in graph")
  assert (#outgoing == #vertices)

  -- Create back hash
  local lookup = {}
  for i=1,#vertices do
    lookup[vertices[i]] = i
  end

  -- Compute ordering of the arcs
  local reordered = {}
  for _,arc in ipairs(outgoing) do
    reordered [lookup[arc.head]] = arc
  end

  -- Copy back
  for i=1,#outgoing do
    outgoing[i] = assert(reordered[i], "illegal vertex order")
  end
end



--- See |outgoing|.
--
function Digraph:incoming(v)
  return assert(v.incomings[self], "vertex not in graph")
end


---
-- See |sortOutgoing|.
--
function Digraph:sortIncoming(v, f)
  table.sort(assert(v.incomings[self], "vertex not in graph"), f)
end


---
-- See |orderOutgoing|.
--
function Digraph:orderIncoming(v, vertices)
  local incoming = assert (v.incomings[self], "vertex not in graph")
  assert (#incoming == #vertices)

  -- Create back hash
  local lookup = {}
  for i=1,#vertices do
    lookup[vertices[i]] = i
  end

  -- Compute ordering of the arcs
  local reordered = {}
  for _,arc in ipairs(incoming) do
    reordered [lookup[arc.head]] = arc
  end

  -- Copy back
  for i=1,#incoming do
    incoming[i] = assert(reordered[i], "illegal vertex order")
  end
end





---
-- Connects two nodes by an arc and returns the newly created arc
-- object. If they are already connected, the existing arc is returned.
--
-- This operation takes time $O(1)$.
--
-- @param s The tail vertex
-- @param t The head vertex (may be identical to |tail| in case of a
--          loop)
--
-- @return The arc object connecting them (either newly created or
--         already existing)
--
function Digraph:connect(s, t)
  assert (s and t and self.vertices[s] and self.vertices[t], "trying connect nodes not in graph")

  local s_outgoings = s.outgoings[self]
  local arc = s_outgoings[t]

  if not arc then
    -- Ok, create and insert new arc object
    arc = {
      tail = s,
      head = t,
      option_cache = {},
      syntactic_digraph = self.syntactic_digraph,
      syntactic_edges = {}
    }
    setmetatable(arc, Arc)

    -- Insert into outgoings:
    s_outgoings [#s_outgoings + 1] = arc
    s_outgoings [t] = arc

    local t_incomings = t.incomings[self]
    -- Insert into incomings:
    t_incomings [#t_incomings + 1] = arc
    t_incomings [s] = arc

    -- Insert into arcs field, if it exists:
    local arcs = rawget(self, "arcs")
    if arcs then
      arcs[#arcs + 1] = arc
    end
  end

  return arc
end




---
-- Disconnect either a single vertex |v| from all its neighbors (remove all
-- incoming and outgoing arcs of this vertex) or, in case two nodes
-- are given as parameter, remove the arc between them, if it exists.
--
-- This operation takes time $O(|I_v| + |I_t|)$, where $I_x$ is the set
-- of vertices incident to $x$, to remove the single arc between $v$ and
-- $v$. For a single vertex $v$, it takes time $O(\sum_{y: \text{there is some
-- arc between $v$ and $y$ or $y$ and $v$}} |I_y|)$.
--
-- @param v The single vertex or the tail vertex
-- @param t The head vertex
--
function Digraph:disconnect(v, t)
  if t then
    -- Case 2: Remove a single arc.
    local s_outgoings = assert(v.outgoings[self], "tail node not in graph")
    local t_incomings = assert(t.incomings[self], "head node not in graph")

    if s_outgoings[t] then
      -- Remove:
      s_outgoings[t] = nil
      for i=1,#s_outgoings do
        if s_outgoings[i].head == t then
          table.remove (s_outgoings, i)
          break
        end
      end
      t_incomings[v] = nil
      for i=1,#t_incomings do
        if t_incomings[i].tail == v then
          table.remove (t_incomings, i)
          break
        end
      end
      self.arcs = nil -- invalidate arcs field
    end
  else
    -- Case 1: Remove all arcs incident to v:

    -- Step 1: Delete all incomings arcs:
    local incomings = assert(v.incomings[self], "node not in graph")
    local vertices = self.vertices

    for i=1,#incomings do
      local s = incomings[i].tail
      if s ~= v and vertices[s] then -- skip self-loop and to-be-deleted nodes
        -- Remove this arc from s:
        local s_outgoings = s.outgoings[self]
        s_outgoings[v] = nil
        for i=1,#s_outgoings do
          if s_outgoings[i].head == v then
            table.remove (s_outgoings, i)
            break
          end
        end
      end
    end

    -- Step 2: Delete all outgoings arcs:
    local outgoings = v.outgoings[self]
    for i=1,#outgoings do
      local t = outgoings[i].head
      if t ~= v and vertices[t] then
        local t_incomings = t.incomings[self]
        t_incomings[v] = nil
        for i=1,#t_incomings do
          if t_incomings[i].tail == v then
            table.remove (t_incomings, i)
            break
          end
        end
      end
    end

    if #incomings > 0 or #outgoings > 0 then
      self.arcs = nil -- invalidate arcs field
    end

    -- Step 3: Reset incomings and outgoings fields
    v.incomings[self] = {}
    v.outgoings[self] = {}
  end
end




---
-- An arc is changed so that instead of connecting |self.tail|
-- and |self.head|, it now connects a new |head| and |tail|. The
-- difference to first disconnecting and then reconnecting is that all
-- fields of the arc (other than |head| and |tail|, of course), will
-- be ``moved along''. Reconnecting an arc in the same way as before has no
-- effect.
--
-- If there is already an arc at the new position, fields of the
-- to-be-reconnected arc overwrite fields of the original arc. This is
-- especially dangerous with a syntactic digraph, so do not reconnect
-- arcs of the syntactic digraph (which you should not do anyway).
--
-- The |arc| object may no longer be valid after a reconnect, but the
-- operation returns the new arc object.
--
-- This operation needs the time of a disconnect (if necessary).
--
-- @param arc The original arc object
-- @param tail The new tail vertex
-- @param head The new head vertex
--
-- @return The new arc object connecting them (either newly created or
--         already existing)
--
function Digraph:reconnect(arc, tail, head)
  assert (arc and tail and head, "connect with nil parameters")

  if arc.head == head and arc.tail == tail then
    -- Nothing to be done
    return arc
  else
    local new_arc = self:connect(tail, head)

    for k,v in pairs(arc) do
      if k ~= "head" and k ~= "tail" then
        new_arc[k] = v
      end
    end

    -- Remove old arc:
    self:disconnect(arc.tail, arc.head)

    return new_arc
  end
end



---
-- Collapse a set of vertices into a single vertex
--
-- Often, algorithms will wish to treat a whole set of vertices ``as a
-- single vertex''. The idea is that a new vertex is then inserted
-- into the graph, and this vertex is connected to all vertices to
-- which any of the original vertices used to be connected.
--
-- The |collapse| method takes an array of to-be-collapsed vertices as
-- well as a vertex. First, it will store references to the
-- to-be-collapsed vertices inside the vertex. Second, we iterate over
-- all arcs of the to-be-collapsed vertices. If this arc connects a
-- to-be-collapsed vertex with a not-to-be-collapsed vertex, the
-- not-to-be-collapsed vertex is connected to the collapse
-- vertex. Additionally, the arc is stored at the vertex.
--
-- Note that the collapse vertex will be added to the graph if it is
-- not already an element. The collapsed vertices will not be removed
-- from the graph, so you must remove them yourself, if necessary.
--
-- A collapse vertex will store the collapsed vertices so that you can
-- call |expand| later on to ``restore'' the vertices and arcs that
-- were saved during a collapse. This storage is \emph{not} local to
-- the graph in which the collapse occurred.
--
-- @param collapse_vertices An array of to-be-collapsed vertices
-- @param collapse_vertex The vertex that represents the collapse. If
-- missing, a vertex will be created automatically and added to the graph.
-- @param vertex_fun This function is called for each to-be-collapsed
-- vertex. The parameters are the collapse vertex and the
-- to-be-collapsed vertex. May be |nil|.
-- @param arc_fun This function is called whenever a new arc is added
-- between |rep| and some other vertex. The arguments are the new arc
-- and the original arc. May be |nil|.
--
-- @return The new vertex that represents the collapsed vertices.

function Digraph:collapse(collapse_vertices, collapse_vertex, vertex_fun, arc_fun)


  -- Create and add node, if necessary.
  if not collapse_vertex then
    collapse_vertex = Vertex.new {}
  end
  self:add {collapse_vertex}

  -- Copy the collapse_vertices and create lookup
  local cvs = {}
  for i=1,#collapse_vertices do
    local v = collapse_vertices[i]
    cvs[i] = v
    cvs[v] = true
  end
  assert (cvs[collapse_vertex] ~= true, "collapse_vertex is in collapse_vertices")

  -- Connected collapse_vertex appropriately
  local collapsed_arcs = {}

  if not arc_fun then
    arc_fun = function () end
  end

  for _,v in ipairs(cvs) do
    if vertex_fun then
      vertex_fun (collapse_vertex, v)
    end
    for _,a in ipairs(v.outgoings[self]) do
      if cvs[a.head] ~= true then
        arc_fun (self:connect(collapse_vertex, a.head), a)
        collapsed_arcs[#collapsed_arcs + 1] = a
      end
    end
    for _,a in ipairs(v.incomings[self]) do
      if cvs[a.tail] ~= true then
        arc_fun (self:connect(a.tail, collapse_vertex), a)
      end
      collapsed_arcs[#collapsed_arcs + 1] = a
    end
  end

  -- Remember the old vertices.
  collapse_vertex.collapsed_vertices = cvs
  collapse_vertex.collapsed_arcs     = collapsed_arcs

  return collapse_vertex
end



---
-- Expand a previously collapsed vertex.
--
-- If you have collapsed a set of vertices in a graph using
-- |collapse|, you can expand this set once more using this method. It
-- will add all vertices that were previously removed from the graph
-- and will also reinstall the deleted arcs. The collapse vertex is
-- not removed.
--
-- @param vertex A to-be-expanded vertex that was previously returned
-- by |collapse|.
-- @param vertex_fun A function that is called once for each
-- reinserted vertex. The parameters are the collapse vertex and the
-- reinstalled vertex. May be |nil|.
-- @param arc_fun A function that is called once for each
-- reinserted arc. The parameter is the arc and the |vertex|. May be |nil|.
--
function Digraph:expand(vertex, vertex_fun, arc_fun)
  local cvs = assert(vertex.collapsed_vertices, "no expand information stored")

  -- Add all vertices:
  self:add(cvs)
  if vertex_fun then
    for _,v in ipairs(cvs) do
      vertex_fun(vertex, v)
    end
  end

  -- Add all arcs:
  for _,arc in ipairs(vertex.collapsed_arcs) do
    local new_arc = self:connect(arc.tail, arc.head)

    for k,v in pairs(arc) do
      if k ~= "head" and k ~= "tail" then
        new_arc[k] = v
      end
    end

    if arc_fun then
      arc_fun(new_arc, vertex)
    end
  end
end





---
-- Invokes the |sync| method for all arcs of the graph.
--
-- @see Arc:sync()
--
function Digraph:sync()
  for _,a in ipairs(self.arcs) do
    a:sync()
  end
end



---
-- Computes a string representation of this graph including all nodes
-- and edges. The syntax of this representation is such that it can be
-- used directly in \tikzname's |graph| syntax.
--
-- @return |self| as string.
--
function Digraph:__tostring()
  local vstrings = {}
  local astrings = {}
  for i,v in ipairs(self.vertices) do
    vstrings[i] = "    " .. tostring(v) .. "[x=" .. math.floor(v.pos.x) .. "pt,y=" .. math.floor(v.pos.y) .. "pt]"
    local out_arcs = v.outgoings[self]
    if #out_arcs > 0 then
      local t = {}
      for j,a in ipairs(out_arcs) do
        t[j] = tostring(a.head)
      end
      astrings[#astrings + 1] = "  " .. tostring(v) .. " -> { " .. table.concat(t,", ") .. " }"
    end
  end
  return "graph [id=" .. tostring(self.vertices) .. "] {\n  {\n" ..
    table.concat(vstrings, ",\n") .. "\n  }; \n" ..
    table.concat(astrings, ";\n") .. "\n}";
end




-- Done

return Digraph
