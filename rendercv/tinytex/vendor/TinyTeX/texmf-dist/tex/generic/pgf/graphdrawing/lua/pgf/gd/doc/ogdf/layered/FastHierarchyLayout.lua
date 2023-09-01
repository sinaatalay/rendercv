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
key           "FastHierarchyLayout"
summary       "Coordinate assignment phase for the Sugiyama algorithm by Buchheim et al."
documentation
[[
This class implements a hierarchy layout algorithm, that is, it
layouts hierarchies with a given order of nodes on each
layer. It is used as a third phase of the Sugiyama algorithm.

All edges of the layout will have at most two
bends. Additionally, for each edge having exactly two bends, the
segment between them is drawn vertically. This applies in
particular to the long edges arising in the first phase of the
Sugiyama algorithm.

The implementation is based on:
%
\begin{itemize}
  \item
    Christoph Buchheim, Michael Jünger, Sebastian Leipert: A Fast
    Layout Algorithm for k-Level Graphs. \emph{Proc. Graph
    Drawing 2000}, volume 1984 of LNCS, pages 229--240, 2001.
\end{itemize}
]]

example
[[
\tikz \graph [SugiyamaLayout, FastHierarchyLayout] {
  a -- {b,c,d} -- e -- a;
};
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key           "FastHierarchyLayout.fixedLayerDistance"
summary       "If true, the distance between neighbored layers is fixed, otherwise variable."
--------------------------------------------------------------------




--------------------------------------------------------------------
key           "FastHierarchyLayout.layerDistance"
summary       "Separation distance (padding) between two consecutive layers."

documentation
[[
Sets the (minimum?) padding between nodes on two consecutive
layers. It defaults to the sum of the keys
|level pre sep| and |level post sep|.
]]

example
[[
\tikz \graph [SugiyamaLayout, FastHierarchyLayout,
              level sep=1cm] {
  a -- {b,c,d} -- e -- a;
};
]]
--------------------------------------------------------------------

--------------------------------------------------------------------
key           "FastHierarchyLayout.nodeDistance"
summary       "Separation distance (padding) between two consecutive nodes on the same layer."

documentation
[[
Sets the (minimum?) padding between sibling nodes. It defaults to the
sum of the keys |sibling pre sep| and |sibling post sep|.
]]

example
[[
\tikz \graph [SugiyamaLayout, FastHierarchyLayout,
              sibling sep=5mm] {
  a -- {b,c,d} -- e -- a;
};
]]
--------------------------------------------------------------------
