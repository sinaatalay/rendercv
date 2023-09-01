-- Copyright 2013 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local key           = require 'pgf.gd.doc'.key
local documentation = require 'pgf.gd.doc'.documentation
local summary       = require 'pgf.gd.doc'.summary
local example       = require 'pgf.gd.doc'.example


--------------------------------------------------------------------
key           "FastSimpleHierarchyLayout"
summary       "Coordinate assignment phase for the Sugiyama algorithm by Ulrik Brandes and Boris Köpf."

documentation
[[
This class implements a hierarchy layout algorithm, that is, it
layouts hierarchies with a given order of nodes on each
layer. It is used as a third phase of the Sugiyama algorithm.

The algorithm runs in three phases:
%
\begin{enumerate}
  \item Alignment (4x)
  \item Horizontal Compactation (4x)
  \item Balancing
\end{enumerate}
%
The alignment and horizontal compactification phases are calculated
downward, upward, left-to-right and right-to-left. The four
resulting layouts are combined in a balancing step.

Warning: The implementation is known to not always produce a
correct layout. Therefore this Algorithm is for testing purpose
only.

The implementation is based on:
%
\begin{itemize}
  \item
    Ulrik Brandes, Boris Köpf: Fast and Simple Horizontal
    Coordinate Assignment. \emph{LNCS} 2002, Volume 2265/2002,
    pp. 33--36
\end{itemize}
]]

example
[[
\tikz \graph [SugiyamaLayout, FastSimpleHierarchyLayout] {
  a -- {b,c,d} -- e -- a;
};
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key           "FastSimpleHierarchyLayout.layerDistance"
summary       "Distance between the centers of nodes of two consecutive layers."

documentation
[[
Sets the (minimum?) distance between nodes on two consecutive
layers. It defaults to the key |level distance|.
]]
example
[[
\tikz \graph [SugiyamaLayout, FastSimpleHierarchyLayout,
              level distance=2cm] {
  a -- {b,c,d} -- e -- a;
};
]]
--------------------------------------------------------------------

--------------------------------------------------------------------
key           "FastSimpleHierarchyLayout.siblingDistance"
summary       "Distance between the centers of nodes of sibling nodes."

documentation
[[
Sets the (minimum?) padding between sibling nodes. It defaults to
|sibling distance|.
]]
example
[[
\tikz \graph [SugiyamaLayout, FastSimpleHierarchyLayout,
              sibling distance=5mm] {
  a -- {b,c,d} -- e -- a;
};
]]
--------------------------------------------------------------------
