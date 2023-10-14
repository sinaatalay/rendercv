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
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare


---
-- @section subsubsection {Forces and Their Effects: Springs}
--
-- The most important parameter of springs is their ``natural
-- length'', which can be configured using the general-purpose
-- |node distance| parameter. It is the ``equilibrium length'' of a
-- spring between two nodes in the graph. When an edge has this
-- length, no forces will ``push'' or ``pull'' along the edge.
--
-- The following examples shows how a simple graph can be scaled by
-- changing the |node distance|:
-- %
-- \begin{codeexample}[preamble={\usetikzlibrary{graphs.standard,graphdrawing}
--    \usegdlibrary{force}}]
-- \tikz \graph [spring layout, node distance=7mm] { subgraph C_n[n=3] };
-- \tikz \graph [spring layout]                    { subgraph C_n[n=3] };
-- \tikz \graph [spring layout, node distance=15mm]{ subgraph C_n[n=3] };
-- \end{codeexample}
-- %
-- \begin{codeexample}[preamble={\usetikzlibrary{graphs.standard,graphdrawing}
--    \usegdlibrary{force}}]
-- \tikz \graph [spring electrical layout, node distance=0.7cm] { subgraph C_n[n=3] };
-- \tikz \graph [spring electrical layout]                      { subgraph C_n[n=3] };
-- \tikz \graph [spring electrical layout, node distance=1.5cm] { subgraph C_n[n=3] };
-- \end{codeexample}
--
-- @end


---

declare {
  key = "spring constant",
  type = "number",
  initial = "0.01",

  summary = [["
    The ``spring constant'' is a factor from Hooke's law describing the
    ``stiffness'' of a spring. This factor is used inside spring-based
    algorithms to determine how strongly edges ``pull'' and ``push'' at
    the nodes they connect.
  "]]
}
