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
-- An |Edge| is a ``syntactic'' connection between two
-- vertices that represents a connection present in the syntactic
-- digraph. Unlike an |Arc|, |Edge| objects are not controlled by the
-- |Digraph| class. Also unlike |Arc| objects, there can be several
-- edges between the same vertices, namely whenever several such edges
-- are present in the syntactic digraph.
--
-- In detail, the relationship between arcs and edges is as follows:
-- If there is an |Edge| between two vertices $u$ and $v$ in the
-- syntactic digraph, there will be an |Arc| from $u$ to $v$ and the
-- array |syntactic_edges| of this |Arc| object will contain the
-- |Edge| object. In particular, if there are several edges between
-- the same vertices, all of these edges will be part of the array in
-- a single |Arc| object.
--
-- Edges, like arcs, are always directed from a |tail| vertex to a
-- |head| vertex; this is true even for undirected vertices. The
-- |tail| vertex will always be the vertex that came first in the
-- syntactic specification of the edge, the |head| vertex is the
-- second one. Whether
-- an edge is directed or not depends on the |direction| of the edge, which
-- may be one of the following:
-- %
-- \begin{enumerate}
--   \item |"->"|
--   \item |"--"|
--   \item |"<-"|
--   \item |"<->"|
--   \item |"-!-"|
-- \end{enumerate}
--
--
-- @field head The head vertex of this edge.
--
-- @field tail The tail vertex of this edge.
--
-- @field event The creation |Event| of this edge.
--
-- @field options A table of options that contains user-defined options.
--
-- @field direction One of the directions named above.
--
-- @field path A |Path| object that describes the path of the
-- edge. The path's coordinates are interpreted \emph{absolutely}.
--
-- @field generated_options This is an options array that is generated
-- by the algorithm. When the edge is rendered later on, this array
-- will be passed back to the display layer. The syntax is the same as
-- for the |declare_parameter_sequence| function, see
-- |InterfaceToAlgorithms|.
--
-- @field animations An array of animations, see the |animations|
-- field of the |Vertex| class for the syntax.

local Edge = {}
Edge.__index = Edge


-- Namespace

require("pgf.gd.model").Edge = Edge


-- Imports

local Path         = require "pgf.gd.model.Path"


---
-- Create a new edge. The |initial| parameter allows you to setup
-- some initial values.
--
-- @usage 
--\begin{codeexample}[code only, tikz syntax=false]
--local v = Edge.new { tail = v1, head = v2 }
--\end{codeexample}
--
-- @param initial Values to override defaults. --
-- @return A new edge object.
--
function Edge.new(values)
  local new = {}
  for k,v in pairs(values) do
    new[k] = v
  end
  new.generated_options = new.generated_options or {}
  new.animations = new.animations or {}
  if not new.path then
    local p = Path.new ()
    p:appendMoveto(Edge.tailAnchorForEdgePath(new))
    p:appendLineto(Edge.headAnchorForEdgePath(new))
    new.path = p
  end

  return setmetatable(new, Edge)
end




---
-- This method returns a ``coordinate factory'' that can be used as
-- the coordinate of a |moveto| at the beginning of a path starting at
-- the |tail| of the arc. Suppose you want to create a path starting
-- at the tail vertex, going to the coordinate $(10,10)$ and ending at
-- the head vertex. The trouble is that when you create the path
-- corresponding to this route, you typically do not know where the
-- tail vertex is going to be. In this case, you use this
-- method to get a function that will, later on, compute the correct
-- position of the anchor as needed.
--
-- Note that you typically do not use this function, but use the
-- corresponding function of the |Arc| class. Use this function only
-- if there are multiple edges between two vertices that need to be
-- routed differently.
--
-- Here is the code you would use to create the above-mentioned path:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--local a = g:connect(tail,head)
--local e = a.syntactic_edges[1]
--...
--e.path = Path.new()
--e.path:appendMoveto(e:tailAnchorForEdgePath())
--e.path:appendLineto(10, 10)
--e.path:appendLineto(e:headAnchorForEdgePath())
--\end{codeexample}
--
-- As for the |Arc| class, you can also setup a polyline more easily:
-- %
--\begin{codeexample}[code only, tikz syntax=false]
--e:setPolylinePath { Coordinate.new (10, 10) }
--\end{codeexample}

function Edge:tailAnchorForEdgePath()
  return function ()
    local a = self.options['tail anchor']
    if a == "" then
      a = "center"
    end
    return self.tail:anchor(a) + self.tail.pos
  end
end

---
-- See |Arc:tailAnchorForArcPath|.

function Edge:headAnchorForEdgePath()
  return function ()
    local a = self.options['head anchor']
    if a == "" then
      a = "center"
    end
    return self.head:anchor(a) + self.head.pos
  end
end



---
-- Setup the |path| field of an edge in such a way that it corresponds
-- to a sequence of straight line segments starting at the tail's
-- anchor and ending at the head's anchor.
--
-- @param coordinates An array of |Coordinates| through which the line
-- will go through.

function Edge:setPolylinePath(coordinates)
  local p = Path.new ()

  p:appendMoveto(self:tailAnchorForEdgePath())

  for _,c in ipairs(coordinates) do
    p:appendLineto(c)
  end

  p:appendLineto(self:headAnchorForEdgePath())

  self.path = p
end



--
-- Returns a string representation of an edge. This is mainly for debugging.
--
-- @return The Edge as a string.
--
function Edge:__tostring()
  return tostring(self.tail) .. self.direction .. tostring(self.head)
end


-- Done

return Edge
