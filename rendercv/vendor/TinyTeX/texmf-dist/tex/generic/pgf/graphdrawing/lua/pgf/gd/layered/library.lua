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
-- A ``layered'' layout of a graph tries to arrange the nodes in
-- consecutive horizontal layers (naturally, by rotating the graph, this
-- can be changed in to vertical layers) such that edges tend to be only
-- between nodes on adjacent layers. Trees, for instance, can always be
-- laid out in this way. This method of laying out a graph is especially
-- useful for hierarchical graphs.
--
-- The method implemented in this library is often called the
-- \emph{Sugiyama method}, which is a rather advanced method of
-- assigning nodes to layers and positions on these layers. The same
-- method is also used in the popular GraphViz program, indeed, the
-- implementation in \tikzname\ is based on the same pseudo-code from the
-- same paper as the implementation used in GraphViz and both programs
-- will often generate the same layout (but not always, as explained
-- below). The current implementation is due to Jannis Pohlmann, who
-- implemented it as part of his Diploma thesis. Please consult this
-- thesis for a detailed explanation of the Sugiyama method and its
-- history:
-- %
-- \begin{itemize}
--   \item
--     Jannis Pohlmann,
--     \newblock \emph{Configurable Graph Drawing Algorithms
--       for the \tikzname\ Graphics Description Language,}
--     \newblock Diploma Thesis,
--     \newblock Institute of Theoretical Computer Science, Universit\"at
--       zu L\"ubeck, 2011.\\[.5em]
--     \newblock Available online via
--       \url{http://www.tcs.uni-luebeck.de/downloads/papers/2011/}\\
--       \url{2011-configurable-graph-drawing-algorithms-jannis-pohlmann.pdf}
--       \\[.5em]
--       (Note that since the publication of this thesis some option names
--       have been changed. Most noticeably, the option name
--       |layered drawing| was changed to |layered layout|, which is somewhat
--       more consistent with other names used in the graph drawing
--       libraries. Furthermore, the keys for choosing individual
--       algorithms for the different algorithm phases, have all changed.)
-- \end{itemize}
--
-- The Sugiyama methods lays out a graph in five steps:
-- %
-- \begin{enumerate}
--   \item Cycle removal.
--   \item Layer assignment (sometimes called node ranking).
--   \item Crossing minimization (also referred to as node ordering).
--   \item Node positioning (or coordinate assignment).
--   \item Edge routing.
-- \end{enumerate}
-- %
-- It turns out that behind each of these steps there lurks an
-- NP-complete problem, which means, in practice, that each step is
-- impossible to perform optimally for larger graphs. For this reason,
-- heuristics and approximation algorithms are used to find a ``good''
-- way of performing the steps.
--
-- A distinctive feature of Pohlmann's implementation of the Sugiyama
-- method for \tikzname\ is that the algorithms used for each of the
-- steps can easily be exchanged, just specify a different option. For
-- the user, this means that by specifying a different option and thereby
-- using a different heuristic for one of the steps, a better layout can
-- often be found. For the researcher, this means that one can very
-- easily test new approaches and new heuristics without having to
-- implement all of the other steps anew.
--
-- @library

local layered


-- Load declarations from:
require "pgf.gd.layered"

-- Load algorithms from:
require "pgf.gd.layered.Sugiyama"
require "pgf.gd.layered.cycle_removal"
require "pgf.gd.layered.node_ranking"
require "pgf.gd.layered.crossing_minimization"
require "pgf.gd.layered.node_positioning"
require "pgf.gd.layered.edge_routing"

