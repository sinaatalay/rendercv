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
-- @section subsubsection {Start Configuration}
--
-- Currently, the start configuration for force-based algorithms is a
-- random distribution of the vertices. You can influence it by
-- changing the |random seed|:
-- %
-- \begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
--    \usegdlibrary{force}}]
-- \tikz \graph [random seed=10, spring layout] {
--   a -- {b, c, d} -- e -- f -- {g,h} -- {a,b,e};
-- };
-- \end{codeexample}
-- %
-- \begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
--    \usegdlibrary{force}}]
-- \tikz \graph [random seed=11, spring layout] {
--   a -- {b, c, d} -- e -- f -- {g,h} -- {a,b,e};
-- };
-- \end{codeexample}
--
-- Other methods, like a planar preembedding, are not implemented
-- currently.
--
-- @end
