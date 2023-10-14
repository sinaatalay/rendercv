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
-- A |Vertex| instance models a node of graphs. Each |Vertex| object can be an 
-- element of any number of graphs (whereas an |Arc| object can only be an
-- element of a single graph). 
-- 
-- When a vertex is added to a digraph |g|, two tables are created in
-- the vertex' storage: An array of incoming arcs (with respect to
-- |g|) and an array of outgoing arcs (again, with respect to
-- |g|). The fields are managed by the |Digraph| class and should not
-- be modified directly.
--
-- Note that a |Vertex| is an abstraction of \tikzname\ nodes; indeed
-- the objective is to ensure that, in principle, we can use them
-- independently of \TeX. For this reason, you will not find any
-- references to |tex| inside a |Vertex|; this information is only
-- available in the syntactic digraph.
--
-- One important aspect of vertices are its anchors -- a concept well
-- familiar for users of \tikzname, but since we need to abstract from
-- \tikzname, a separate anchor management is available inside the
-- graph drawing system. It works as follows:
--
-- First of all, every vertex has a path, which is a (typically
-- closed) line around the vertex. The display system will pass down
-- the vertex' path to the graph drawing system and this path will be
-- stored as a |Path| object in the |path| field of the vertex. This
-- path lives in a special ``local'' coordinate system, that is, all
-- coordinates of this path should actually be considered relative to
-- the vertex' |pos| field. Note that the path is typically, but not
-- always, ``centered'' on the origin. A graph drawing algorithm
-- should arrange the vertices in such a way that the origins in the
-- path coordinate systems are aligned.
--
-- To illustrate the difference between the origin and the vertex
-- center, consider a tree drawing algorithm in which a node |root| has
-- three children |a|, |b|, and |g|. Now, if we were to simply center
-- these three letters vertically and arrange them in a line, the
-- letters would appear to ``jump up and down'' since the height of
-- the three letters are quite different. A solution is to shift the
-- letters (and, thus, the paths of the vertices) in such a way that
-- in all three letters the baseline of the letters is exactly at the
-- origin. Now, when a graph drawing algorithm aligns these vertices
-- along the origins, the letters will all have the same baseline. 
--
-- Apart from the origin, there may be other positions in the path
-- coordinate system that are of interest -- such as the center of
-- the vertex. As mentioned above, this need not be the origin and
-- although a graph drawing algorithm should align the origins,
-- \emph{edges} between vertices should head toward these vertex
-- centers rather that toward the origins. Other points of interest
-- might be the ``top'' of the node. 
--
-- All points of special interest are called ``anchors''. The |anchor|
-- method allows you to retrieve them. By default, you always have
-- access to the |center| anchor, but other anchors may or may not be
-- available also, see the |anchor| method for details.
--
-- @field pos A coordinate object that stores the position where the
-- vertex should be placed on the canvas. The main objective of graph drawing
-- algorithms is to update this coordinate.
--
-- @field name An optional string that is used as a textual representation
--        of the node.
--
-- @field path The path of the vertex's shape. This is a path along
-- the outer line resulting from stroking the vertex's original
-- shape. For instance, if you have a quadratic shape of size 1cm and
-- you stroke the path with a pen of 2mm thickness, this |path| field
-- would store a path of a square of edge length 12mm. 
--
-- @field anchors A table of anchors (in the TikZ sense). The table is
-- indexed by the anchor names (strings) and the values are
-- |Coordinate|s. Currently, it is only guaranteed that the |center|
-- anchor is present. Note that the |center| anchor need not lie at
-- the origin: A graph drawing system should align nodes relative to
-- the origin of the path's coordinate system. However, lines going to
-- and from the node will head towards the |center| anchor. See
-- Section~\ref{section-gd-anchors} for details.
--
-- @field options A table of options that contains user-defined options.
--
-- @field animations An array of attribute animations for the
-- node. When an algorithm adds entries to this array, the display
-- layer should try to render these. The syntax is as follows: Each
-- element in the array is a table with a field |attribute|, which must
-- be a string like |"opacity"| or |"translate"|, a field |entries|,
-- which must be an array to be explained in a moment, and field
-- |options|, which must be a table of the same syntax as the
-- |options| field. For the |entries| array, each element must be
-- table with two field: |t| must be set to a number, representing a
-- time in seconds, and |value|, which must be set to a value that
-- the |attribute| should have at the given time. The entries and the
-- options will then be interpreted as described in \pgfname's basic
-- layer animation system, except that where a |\pgfpoint| is expected
-- you provide a |Coordinate| and a where a path is expected you
-- provide a |Path|.
--
-- @field shape A string describing the shape of the node (like |rectangle|
-- or |circle|). Note, however, that this is more ``informative''; the
-- actual information that is used by the graph drawing system for
-- determining the extent of a node, its bounding box, convex hull,
-- and line intersections is the |path| field. 
--
-- @field kind A string describing the kind of the node. For instance, a
--        node of type |"dummy"| does not correspond to any real node in
--        the graph but is used by the graph drawing algorithm.
--
-- @field event The |Event| when this vertex was created (may be |nil|
-- if the vertex is not part of the syntactic digraph).
--
-- @field incomings A table indexed by |Digraph| objects. For each
-- digraph, the table entry is an array of all vertices from which
-- there is an |Arc| to this vertex. This field is internal and may
-- not only be accessed by the |Digraph| class.
--
-- @field outgoings Like |incomings|, but for outgoing arcs.
--
local Vertex = {}
Vertex.__index = Vertex


-- Namespace

require("pgf.gd.model").Vertex = Vertex


-- Imports

local Coordinate   = require "pgf.gd.model.Coordinate"
local Path         = require "pgf.gd.model.Path"
local Storage      = require "pgf.gd.lib.Storage"


--- 
-- Create a new vertex. The |initial| parameter allows you to setup
-- some initial values.
--
-- @usage 
--\begin{codeexample}[code only, tikz syntax=false]
--local v = Vertex.new { name = "hello", pos = Coordinate.new(1,1) }
--\end{codeexample} 
--
-- @param initial Values to override default node settings. The
-- following are permissible:
-- \begin{description}
-- \item[|pos|] Initial position of the node.
-- \item[|name|] The name of the node. It is optional to define this.
-- \item[|path|] A |Path| object representing the vertex's hull. 
-- \item[|anchors|] A table of anchors.
-- \item[|options|] An options table for the vertex.
-- \item[|animations|] An array of generated animation attributes.
-- \item[|shape|] A string describing the shape. If not given, |"none"| is used.
-- \item[|kind|] A kind like |"node"| or |"dummy"|. If not given, |"dummy"| is used.
-- \end{description}
--
-- @return A newly allocated node.
--
function Vertex.new(values)
  local new = {
    incomings = Storage.new(),
    outgoings = Storage.new()
  }
  for k,v in pairs(values) do
    new[k] = v
  end
  new.path = new.path or Path.new { 0, 0 }
  new.shape = new.shape or "none"
  new.kind = new.kind or "dummy"
  new.pos = new.pos or Coordinate.new(0,0)
  new.anchors = new.anchors or { center = Coordinate.new(0,0) }
  new.animations = new.animations or {}
  return setmetatable (new, Vertex)
end




---
-- Returns a bounding box of a vertex. 
--
-- @return |min_x| The minimum $x$ value of the bounding box of the path
-- @return |min_y| The minimum $y$ value
-- @return |max_x|
-- @return |max_y|
-- @return |center_x| The center of the bounding box
-- @return |center_y| 

function Vertex:boundingBox()
  return self.path:boundingBox()
end



local anchor_cache = Storage.new ()

local directions = {
  north = function(min_x, min_y, max_x, max_y)
      return (min_x+max_x)/2, max_y
    end,
  south = function(min_x, min_y, max_x, max_y)
      return (min_x+max_x)/2, min_y
    end,
  east  = function(min_x, min_y, max_x, max_y)
      return max_x, (min_y+max_y)/2
    end,
  west  = function(min_x, min_y, max_x, max_y)
      return min_x, (min_y+max_y)/2
    end,
  ["north west"] = function(min_x, min_y, max_x, max_y)
      return min_x, max_y
    end,
  ["north east"] = function(min_x, min_y, max_x, max_y)
        return max_x, max_y
      end,
  ["south west"] = function(min_x, min_y, max_x, max_y)
        return min_x, min_y
      end,
  ["south east"] = function(min_x, min_y, max_x, max_y)
        return max_x, min_y
      end,
}

---
-- Returns an anchor position in a vertex. First, we try to look 
-- the anchor up in the vertex's |anchors| table. If it is not found
-- there, we test whether it is one of the direction strings |north|,
-- |south east|, and so on. If so, we consider a line from the center
-- of the node to the position on the bounding box that corresponds to
-- the given direction (so |south east| would be the lower right
-- corner). We intersect this line with the vertex's path and return
-- the result. Finally, if the above fails, we try to consider the
-- anchor as a number and return the intersection of a line starting
-- at the vertex's center with the number as its angle and the path of
-- the vertex.
--
-- @param anchor An anchor as detailed above
-- @return A coordinate in the vertex's local coordinate system (so
-- add the |pos| field to arrive at the actual position). If the
-- anchor was not found, |nil| is returned

function Vertex:anchor(anchor)
  local c = self.anchors[anchor]
  if not c then
    local b
    local d = directions [anchor]
    if d then
      b = Coordinate.new(d(self:boundingBox()))
    else
      local n = tonumber(anchor)
      if n then
        local x1, y1, x2, y2 = self:boundingBox()
        local r = math.max(x2-x1, y2-y1)
        b = Coordinate.new(r*math.cos(n/180*math.pi),r*math.sin(n/180*math.pi))
        b:shiftByCoordinate(self.anchors.center)
      end
    end
    if not b then
      return
    end
    local p = Path.new {'moveto', self.anchors.center, 'lineto', b}
    local intersections = p:intersectionsWith(self.path)
    if #intersections > 0 then
      c = intersections[1].point
    end
  end
  self.anchors[anchor] = c
  return c
end



--
-- Returns a string representation of a vertex. This is mainly for debugging
--
-- @return The Arc as string.
--
function Vertex:__tostring()
  return self.name or tostring(self.anchors)
end


-- Done

return Vertex
