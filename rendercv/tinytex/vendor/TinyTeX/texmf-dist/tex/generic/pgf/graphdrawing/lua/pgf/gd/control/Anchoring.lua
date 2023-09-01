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
-- @section subsection {Anchoring a Graph}
--
-- \label{subsection-library-graphdrawing-anchoring}
--
-- A graph drawing algorithm must compute positions of the nodes of a
-- graph, but the computed positions are only \emph{relative} (``this
-- node is left of this node, but above that other node''). It is not
-- immediately obvious where the ``the whole graph'' should be placed
-- \emph{absolutely} once all relative positions have been computed. In
-- case that the graph consists of several unconnected components, the
-- situation is even more complicated.
--
-- The order in which the algorithm layer determines the node at which
-- the graph should be anchored:
-- %
-- \begin{enumerate}
--   \item If the |anchor node=|\meta{node name} option given to the graph
--     as a whole, the graph is anchored at \meta{node name}, provided
--     there is a node of this name in the graph. (If there is no node of
--     this name or if it is misspelled, the effect is the same as if this
--     option had not been given at all.)
--   \item Otherwise, if there is a node where the |anchor here| option is
--     specified, the first node with this option set is used.
--   \item Otherwise, if there is a node where the |desired at| option is
--     set (perhaps implicitly through keys like |x|), the first such node
--     is used.
--   \item Finally, in all other cases, the first node is used.
-- \end{enumerate}
--
-- In the above description, the ``first'' node refers to the node first
-- encountered in the specification of the graph.
--
-- Once the node has been determined, the graph is shifted so that
-- this node lies at the position specified by |anchor at|.
--
-- @end



local Anchoring = {}


-- Namespace
require("pgf.gd.control").Anchoring = Anchoring


-- Imports
local Coordinate = require("pgf.gd.model.Coordinate")
local declare    = require "pgf.gd.interface.InterfaceToAlgorithms".declare



---
declare {
  key = "desired at",
  type = "coordinate",
  documentation_in = "pgf.gd.control.doc"
}

---
declare {
  key = "anchor node",
  type = "string",
  documentation_in = "pgf.gd.control.doc"
}


---
declare {
  key = "anchor at",
  type = "canvas coordinate",
  initial = "(0pt,0pt)",
  documentation_in = "pgf.gd.control.doc"
}


---
declare {
  key = "anchor here",
  type = "boolean",
  documentation_in = "pgf.gd.control.doc"
}





-- Done

return Anchoring