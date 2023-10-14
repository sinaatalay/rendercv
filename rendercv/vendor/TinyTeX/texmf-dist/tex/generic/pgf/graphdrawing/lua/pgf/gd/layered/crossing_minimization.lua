-- Copyright 2012 by Till Tantau
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare


---
-- @section subsection {Crossing Minimization (Node Ordering)}
--
-- The number of edge crossings in a layered drawing is determined by
-- the ordering of nodes at each of its layers. Therefore, crossing
-- minimization is the problem of reordering the nodes at each layer
-- so that the overall number of edge crossings is minimized. The
-- crossing minimization step takes a proper layering where every edge
-- connects nodes in neighbored layers, allowing algorithms to
-- minimize crossings layer by layer rather than all at once. While
-- this does not reduce the complexity of the problem, it does make it
-- considerably easier to understand and implement. Techniques based
-- on such an iterative approach are also known as layer-by-layer
-- sweep methods. They are used in many popular heuristics due to
-- their simplicity and the good results they produce.
--
-- Sweeping refers to moving up and down from one layer to the next,
-- reducing crossings along the way. In layer-by-layer sweep methods,
-- an initial node ordering for one of the layers is computed
-- first. Depending on the sweep direction this can either be the
-- first layer or the last; in rare occasions the layer in the middle
-- is used instead. Followed by this, the actual layer-by-layer sweep
-- is performed. Given an initial ordering for the first layer $L_1$, a
-- downward sweep first holds the nodes in $L_1$ fixed while reordering
-- the nodes in the second layer $L_2$ to reduce the number of
-- crossings between $L_1$ and $L_2$. It then goes on to reorder the
-- third layer while holding the second layer fixed. This is continued
-- until all layers except for the first one have been
-- examined. Upward sweeping and sweeping from the middle work
-- analogous.
--
-- Obviously, the central aspect of the layer-by-layer sweep is how
-- the nodes of a specific layer are reordered using a neighbored
-- layer as a fixed reference. This problem is known as one-sided
-- crossing minimization, which unfortunately is NP-hard. In the
-- following various heuristics to solve this problem are
-- presented.
--
-- For more details, please see Section 4.1.4 of Pohlmann's Diploma
-- thesis.
--
-- @end



---

declare {
  key = "sweep crossing minimization",
  algorithm = require "pgf.gd.layered.CrossingMinimizationGansnerKNV1993",
  phase = "crossing minimization",
  phase_default = true,

  summary = [["
    Gansner et al. combine an initial ordering based on a depth-first
    search with the median and greedy switch heuristics applied in the
    form of an alternating layer-by-layer sweep based on a weighted
    median.
  "]],
  documentation = [["
    For more details, please see Section~4.1.4 of Pohlmann's Diploma
    thesis.

    This is the default algorithm for crossing minimization.
  "]]
}
