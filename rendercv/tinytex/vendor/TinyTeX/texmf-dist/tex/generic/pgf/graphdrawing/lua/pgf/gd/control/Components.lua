-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Imports

local declare       = require "pgf.gd.interface.InterfaceToAlgorithms".declare


---
-- @section subsection {Packing of Connected Components}
--
-- \label{subsection-gd-component-packing}
-- \label{section-gd-packing}
--
-- Graphs may be composed of subgraphs or \emph{components} that are not
-- connected to each other. In order to draw these nicely, most graph
-- drawing algorithms split them into separate graphs, compute
-- their layouts with the same graph drawing algorithm independently and,
-- in a postprocessing step, arrange them next to each other. Note,
-- however, that some graph drawing algorithms can also arrange the nodes
-- of the graph in a uniform way even for unconnected components (the
-- |simple necklace layout| is a case in point); for such algorithms you can
-- choose whether they should be applied to each component individually
-- or not (if not, the following options do not apply). To configure
-- which is the case, use the |componentwise| key.
--
-- The default method for placing the different components works as
-- follows:
-- %
-- \begin{enumerate}
--   \item For each component, a layout is determined and the component is
--     oriented as described
--     Section~\ref{subsection-library-graphdrawing-standard-orientation}
--     on the orientation of graphs.
--   \item The components are sorted as prescribed by the
--     |component order| key.
--   \item The first component is now placed (conceptually) at the
--     origin. (The final position of this and all other components will be
--     determined later, namely in the anchoring phase, but let us imagine
--     that the first component lies at the origin at this point.)
--   \item The second component is now positioned relative to the first
--     component. The ``direction'' in which the next component is placed
--     relative to the first one is determined by the |component direction|
--     key, so components can be placed from left to right or up to down or
--     in any other direction (even something like $30^\circ$). However,
--     both internally and in the following description, we assume that the
--     components are placed from left to right; other directions are
--     achieved by doing some (clever) rotating of the arrangement achieved
--     in this way.
--
--     So, we now wish to place the second component to the right of the
--     first component. The component is first shifted vertically according
--     to some alignment strategy. For instance, it can be shifted so that
--     the topmost node of the first component and the topmost node of the
--     second component have the same vertical position. Alternatively, we
--     might require that certain ``alignment nodes'' in both components
--     have the same vertical position. There are several other strategies,
--     which can be configured using the |component align| key.
--
--     One the vertical position has been fixed, the horizontal position is
--     computed. Here, two different strategies are available: First, image
--     rectangular bounding boxed to be drawn around both components. Then
--     we shift the second component such that the right border of the
--     bounding box of the first component touches the left border of the
--     bounding box of the second component. Instead of having the bounding
--     boxes ``touch'', we can also have a padding of |component sep|
--     between them. The second strategy is more involved and also known as
--     a ``skyline'' strategy, where (roughly) the components are
--     ``moved together as near as possible so that nodes do not touch''.
--   \item
--     After the second component has been placed, the third component is
--     considered and positioned relative to the second one, and so on.
--   \item
--     At the end, as hinted at earlier, the whole arrangement is rotate so
--     that instead of ``going right'' the component go in the direction of
--     |component direction|. Note, however, that this rotation applies only
--     to the ``shift'' of the components; the components themselves are
--     not rotated. Fortunately, this whole rotation process happens in the
--     background and the result is normally exactly what you would expect.
-- \end{enumerate}
--
-- In the following, we go over the different keys that can be used to
-- configure the component packing.
--
-- @end


---

declare {
  key = "componentwise",
  type = "boolean",

  summary = [["
    For algorithms that also support drawing unconnected graphs, use
    this key to enforce that the components of the graph are,
    nevertheless, laid out individually. For algorithms that do not
    support laying out unconnected graphs, this option has no effect;
    rather it works as if this option were always set.
  "]],
  examples = {[["
    \tikz \graph [simple necklace layout]
      {
        a -- b -- c -- d -- a,
        1 -- 2 -- 3 -- 1
      };
    "]],[[",
    \tikz \graph [simple necklace layout, componentwise]
      {
        a -- b -- c -- d -- a,
        1 -- 2 -- 3 -- 1
      };
  "]]
  }
}



