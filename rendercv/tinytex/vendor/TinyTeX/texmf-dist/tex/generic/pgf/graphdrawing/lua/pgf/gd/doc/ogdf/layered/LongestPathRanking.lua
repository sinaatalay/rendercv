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
key          "LongestPathRanking"
summary      "The longest-path ranking algorithm."
documentation
[[
  |LongestPathRanking| implements the well-known longest-path ranking
  algorithm, which can be used as first phase in |SugiyamaLayout|. The
  implementation contains a special optimization for reducing edge
  lengths, as well as special treatment of mixed-upward graphs (for
  instance, \textsc{uml} class diagrams).
]]
--------------------------------------------------------------------


--------------------------------------------------------------------
key          "LongestPathRanking.separateDeg0Layer"
summary      "If set to true, isolated nodes are placed on a separate layer."
--------------------------------------------------------------------


--------------------------------------------------------------------
key          "LongestPathRanking.separateMultiEdges"
summary      "If set to true, multi-edges will span at least two layers."
--------------------------------------------------------------------



--------------------------------------------------------------------
key          "LongestPathRanking.optimizeEdgeLength"
summary
[[
  If set to true the ranking algorithm tries to reduce edge
  length even if this might increase the height of the layout. Choose
  false, if the longest-path ranking known from the literature should be
  used.
]]
--------------------------------------------------------------------


