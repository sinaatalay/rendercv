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
-- @section subsection {Node Positioning (Coordinate Assignment)}
--
-- The second last step of the Sugiyama method decides about the final
-- $x$- and $y$-coordinates of the nodes. The main objectives of this
-- step are to position nodes so that the number of edge bends is kept
-- small and edges are drawn as vertically as possible. Another goal
-- is to avoid node and edge overlaps which is crucial in particular
-- if the nodes are allowed to have non-uniform sizes. The
-- $y$-coordinates of the nodes have no influence on the number of
-- bends. Obviously, nodes need to be separated enough geometrically
-- so that they do not overlap. It feels natural to aim at separating
-- all layers in the drawing by the same amount. Large nodes, however,
-- may force node positioning algorithms to override this uniform
-- level distance in order to avoid overlaps.
--
-- For more details, please see Section~4.1.2 of Pohlmann's Diploma thesis.
--
-- @end



---

declare {
  key = "linear optimization node positioning",
  algorithm = require "pgf.gd.layered.NodePositioningGansnerKNV1993",
  phase = "node positioning",
  phase_default = true,

  summary = [["
    This node positioning method, due to Gasner et al., is based on a
    linear optimization problem.
  "]],
  documentation = [["
    For more details, please see Section~4.1.3 of Pohlmann's Diploma thesis.

    This is the default algorithm for layer assignments.
  "]]
}
