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
key           "OptimalRanking"
summary       "The optimal ranking algorithm."
documentation
[[
  The |OptimalRanking| implements the LP-based algorithm for
  computing a node ranking with minimal edge lengths, which can
  be used as first phase in |SugiyamaLayout|.
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key           "OptimalRanking.separateMultiEdges"
summary       "If set to true, multi-edges will span at least two layers."
--------------------------------------------------------------------
