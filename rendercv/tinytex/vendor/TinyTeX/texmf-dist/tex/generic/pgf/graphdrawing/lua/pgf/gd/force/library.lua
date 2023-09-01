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
-- Nature creates beautiful graph layouts all the time. Consider a
-- spider's web: Nodes are connected by edges in a visually most pleasing
-- manner (if you ignore the spider in the middle). The layout of a
-- spider's web is created just by the physical forces exerted by the
-- threads. The idea behind force-based graph drawing algorithms is to
-- mimic nature: We treat edges as threads that exert forces and simulate
-- into which configuration the whole graph is ``pulled'' by these
-- forces.
--
-- When you start thinking about for a moment, it turns out that there
-- are endless variations of the force model. All of these models have
-- the following in common, however:
-- %
-- \begin{itemize}
--   \item ``Forces'' pull and push at the nodes in different directions.
--   \item The effect of these forces is simulated by iteratively moving
--     all the nodes simultaneously a little in the direction of the forces
--     and by then recalculating the forces.
--   \item The iteration is stopped either after a certain number of
--     iterations or when a \emph{global energy minimum} is reached (a very
--     scientific way of saying that nothing happens anymore).
-- \end{itemize}
--
-- The main difference between the different force-based approaches is
-- how the forces are determined. Here are some ideas what could cause a
-- force to be exerted between two nodes (and there are more):
-- %
-- \begin{itemize}
--   \item If the nodes are connected by an edge, one can treat the edge as
--     a ``spring'' that has a ``natural spring dimension''. If the nodes
--     are nearer than the spring dimension, they are push apart; if they
--     are farther aways than the spring dimension, they are pulled together.
--   \item If two nodes are connected by a path of a certain length, the
--     nodes may ``wish to be at a distance proportional to the path
--     length''. If they are nearer, they are pushed apart; if they are
--     farther, they are pulled together. (This is obviously a
--     generalization of the previous idea.)
--   \item There may be a general force field that pushes nodes apart (an
--     electrical field), so that nodes do not tend to ``cluster''.
--   \item There may be a general force field that pulls nodes together (a
--     gravitational field), so that nodes are not too loosely scattered.
--   \item There may be highly nonlinear forces depending on the distance of
--     nodes, so that nodes very near to each get pushed apart strongly,
--     but the effect wears of rapidly at a distance. (Such forces are
--     known as strong nuclear forces.)
--   \item There rotational forces caused by the angles between the edges
--     leaving a node. Such forces try to create a \emph{perfect angular
--     resolution} (a very scientific way of saying that all angles
--     at a node are equal).
-- \end{itemize}
--
-- Force-based algorithms combine one or more of the above ideas into a
-- single algorithm that uses ``good'' formulas for computing the
-- forces.
--
-- Currently, three algorithms are implemented in this library, two of
-- which are from the first of the following paper, while the third is
-- from the third paper:
-- %
-- \begin{itemize}
--   \item
--     Y. Hu.
--     \newblock Efficient, high-quality force-directed graph drawing.
--     \newblock \emph{The Mathematica Journal}, 2006.
--   \item
--     C. Walshaw.
--     \newblock A multilevel algorithm for force-directed graph
--     drawing.
--     \newblock In J. Marks, editor, \emph{Graph Drawing}, Lecture Notes in
--     Computer Science, 1984:31--55, 2001.
-- \end{itemize}
--
-- Our implementation is described in detail in the following
-- diploma thesis:
-- %
-- \begin{itemize}
--   \item
--     Jannis Pohlmann,
--     \newblock \emph{Configurable Graph Drawing Algorithms
--       for the \tikzname\ Graphics Description Language,}
--     \newblock Diploma Thesis,
--     \newblock Institute of Theoretical Computer Science, Universit\"at
--       zu L\"ubeck, 2011.\\[.5em]
--     \newblock Online at
--       \url{http://www.tcs.uni-luebeck.de/downloads/papers/2011/}\\ \url{2011-configurable-graph-drawing-algorithms-jannis-pohlmann.pdf}
-- \end{itemize}
--
-- In the future, I hope that most, if not all, of the force-based
-- algorithms become ``just configuration options'' of a general
-- force-based algorithm similar to the way the modular Sugiyama method
-- is implemented in the |layered| graph drawing library.
--
-- @library

local force -- Library name

-- Load declarations from:
require "pgf.gd.force.ControlDeclare"
require "pgf.gd.force.ControlStart"
require "pgf.gd.force.ControlIteration"
require "pgf.gd.force.ControlSprings"
require "pgf.gd.force.ControlElectric"
require "pgf.gd.force.ControlCoarsening"

require "pgf.gd.force.SpringLayouts"
require "pgf.gd.force.SpringElectricalLayouts"

-- Load algorithms from:
require "pgf.gd.force.SpringHu2006"
require "pgf.gd.force.SpringElectricalHu2006"
require "pgf.gd.force.SpringElectricalWalshaw2000"

