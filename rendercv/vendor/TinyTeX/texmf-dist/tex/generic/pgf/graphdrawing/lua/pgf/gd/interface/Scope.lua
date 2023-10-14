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
-- In theory, graph drawing algorithms take graphs as input and
-- output graphs embedded into the plane as output. In practice, however,
-- the input to a graph drawing algorithm is not ``just'' the
-- graph. Rather, additional information about the graph, in particular
-- about the way the user specified the graph, is also important to many
-- graph drawing algorithms.
--
-- The graph drawing system gathers both the original input graph as well
-- as all additional information that is provided in the graph drawing
-- scope inside a scope table. The object has a number of fields that
-- inform an algorithm about the input.
--
-- For each graph drawing scope, a new |Scope| object is
-- created. Graph drawing scopes are kept track of using a stack, but
-- only the top of this stack is available to the interface classes.
--
-- @field syntactic_digraph The syntactic digraph is a digraph that
-- faithfully encodes the way the input graph is represented
-- syntactically. However, this does not mean that the syntactic
-- digraph contains the actual textual representation of the input
-- graph. Rather, when an edge is specified as, say, |a <- b|, the
-- syntactic digraph will contains an arc from |a| to |b| with an edge
-- object attached to it that is labeled as a ``backward''
-- edge. Similarly, an edge |a -- b| is also stored as a directed arc
-- from |a| to |b| with the label |--| attached to it. Algorithms will
-- often be more interested graphs derived from the syntactic digraph
-- such as its underlying undirected graph. These derived graphs are
-- made accessible by the graph drawing engine during the preprocessing.
--
-- @field events An array of |Event| objects. These objects, see the
-- |Event| class for details, are created during the parsing of the
-- input graph.
--
-- @field node_names A table that maps the names of nodes to node
-- objects. Every node must have a unique name.
--
-- @field coroutine A Lua coroutine that is used internally to allow
-- callbacks to the display layer to be issued deep down during a run
-- of an algorithm.
--
-- @field collections The collections specified inside the scope, see
-- the |Collection| class.

local Scope = {}
Scope.__index = Scope

-- Namespace
require("pgf.gd.interface").Scope = Scope

-- Imports
local lib     = require "pgf.gd.lib"
local Storage = require "pgf.gd.lib.Storage"

local Digraph = require "pgf.gd.model.Digraph"

---
-- Create a new |Scope| object.
--
-- @param initial A table of initial values for the newly created
-- |Scope| object.
--
-- @return The new scope object.

function Scope.new(initial)
  return setmetatable(lib.copy(initial,
    {
      syntactic_digraph = Digraph.new{},
      events            = {},
      node_names        = {},
      coroutine         = nil,
      collections       = {},
    }), Scope)
end


-- Done

return Scope
