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
-- A collection is essentially a subgraph of a graph, that is, a
-- ``collection'' of some nodes and some edges of the graph. The name
-- ``collection'' was chosen over ``subgraph'' since the latter are
-- often thought of as parts of a graph that are rendered in a special
-- way (such as being surrounded by a rectangle), while collections
-- are used to model such diverse things as hyperedges, sets of
-- vertices that should be on the same level in a layered algorithm,
-- or, indeed, subgraphs that are rendered in a special way.
--
-- Collections are grouped into ``kinds''. All collections of a given
-- kind can be accessed by algorithms through an array whose elements
-- are the collections. On the display layer, for each kind a separate
-- key is available to indicate that a node or an edge belongs to a
-- collection.
--
-- Collections serve two purposes: First, they can be seen as ``hints''
-- to graph drawing algorithms that certain nodes and/or edges ``belong
-- together''. For instance, collections of kind |same layer| are used
-- by the Sugiyama algorithm to group together nodes that should appear
-- at the same height of the output. Second, since collections are also
-- passed back to the display layer in a postprocessing step, they can be
-- used to render complicated concepts such as hyperedges (which are
-- just collections of nodes, after all) or subgraphs.
--
-- @field kind The ``kind'' of the collection.
--
-- @field vertices A lookup table of vertices (that is, both an array
-- with the vertices in the order in which they appear as well as a
-- table such that |vertices[vertex] == true| whenever |vertex| is
-- present in the table.
--
-- @field edges A lookup table of edges (not arcs!).
--
-- @field options An options table. This is the table of options that
-- was in force when the collection was created.
--
-- @field child_collections An array of all collections that are
-- direct children of this collection (that is,
-- they were defined while the current collection was the most
-- recently defined collection on the options stack). However, you
-- should use the methods |children|, |descendants|, and so to access
-- this field.
--
-- @field parent_collection The parent collection of the current
-- collection. This field may be |nil| in case a collection has no parent.
--
-- @field event An |Event| object that was create for this
-- collection. Its |kind| will be |"collection"| while its |parameter|
-- will be the collection kind.

local Collection = {}
Collection.__index = Collection


-- Namespace

require("pgf.gd.model").Collection = Collection


-- Imports
local Storage      = require "pgf.gd.lib.Storage"



---
-- Creates a new collection. You should not call this function
-- directly, it is called by the interface classes.
--
-- @param t A table of initial values. The field |t.kind| must be a
-- nonempty string.
--
-- @return The new collection
--
function Collection.new(t)
  assert (type(t.kind) == "string" and t.kind ~= "", "collection kind not set")

  return setmetatable(
    {
      vertices               = t.vertices or {},
      edges                  = t.edges or {},
      options                = t.options or {},
      generated_options      = t.generated_options or {},
      kind                   = t.kind,
      event                  = t.event,
      child_collections      = t.child_collections or {},
    }, Collection)
end




--
-- An internal function for registering a collection as child of
-- another collection. The collection |self| will be made a child
-- collection of |parent|.
--
-- @param parent A collection.

function Collection:registerAsChildOf(parent)
  self.parent = parent
  if parent then
    assert (getmetatable(parent) == Collection, "parent must be a collection")
    parent.child_collections[#parent.child_collections+1] = self
  end
end



---
-- A collection can have any number of \emph{child collections}, which
-- are collections nested inside the collection. You can access the
-- array of these children through this method. You may not modify
-- the array returned by this function.
--
-- @return The array of children of |self|.
--
function Collection:children()
  return self.child_collections
end


---
-- This method works like the |children| method. However, the tree of
-- collections is, conceptually, contracted by considering only these
-- collections that have the |kind| given as parameter. For instance,
-- if |self| has a child collection of a kind different from |kind|,
-- but this child collection has, in turn, a child collection of kind
-- |kind|, this latter child collection will be included in the array
-- -- but not any of its child collections.
--
-- @param kind The collection kind to which the tree of collections
-- should be restricted.
--
-- @return The array of children of |self| in this contracted tree.
--
function Collection:childrenOfKind(kind)
  local function rec (c, a)
    for _,d in ipairs(c.child_collections) do
      if d.kind == kind then
        a[#a + 1] = d
      else
        rec (d, a)
      end
    end
    return a
  end
  return rec(self, {})
end


---
-- The descendants of a collection are its children, plus their
-- children, plus their children, and so on.
--
-- @return An array of all descendants of |self|. It will be in
-- preorder.

function Collection:descendants()
  local function rec (c, a)
    for _,d in ipairs(c.child_collections) do
      a[#a + 1] = d
      rec (d, a)
    end
    return a
  end
  return rec(self, {})
end



---
-- The descendants of a collection of the given |kind|.
--
-- @param kind A collection kind.
--
-- @return An array of all descendants of |self| of the given |kind|.

function Collection:descendantsOfKind(kind)
  local function rec (c, a)
    for _,d in ipairs(c.child_collections) do
      if d.kind == kind then
        a[#a + 1] = d
      end
      rec (d, a)
    end
    return a
  end
  return rec(self, {})
end



-- Done

return Collection
