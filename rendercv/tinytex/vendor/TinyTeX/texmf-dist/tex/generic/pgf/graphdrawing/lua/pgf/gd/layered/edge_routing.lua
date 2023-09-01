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
-- @section subsection {Edge Routing}
--
-- The original layered drawing method described by Eades and Sugiyama
-- in does not include the routing or shaping of edges as a main
-- step. This makes sense if all nodes have the same size and
-- shape. In practical scenarios, however, this assumption often does
-- not hold. In these cases, advanced techniques may have to be
-- applied in order to avoid overlaps of nodes and edges.
--
-- For more details, please see Section~4.1.5 of Pohlmann's Diploma
-- thesis.
--
-- @end



---

declare {
  key = "polyline layer edge routing",
  algorithm = require "pgf.gd.layered.EdgeRoutingGansnerKNV1993",
  phase = "layer edge routing",
  phase_default = true,

  summary = [["
    This edge routing algorithm uses polygonal lines to connect nodes.
  "]],
  documentation = [["
    For more details, please see Section~4.1.5 of Pohlmann's Diploma thesis.

    This is the default algorithm for edge routing.
  "]]
}
