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
key           "CoffmanGrahamRanking"
summary       "The ranking algorithm due to Coffman and Graham."
documentation
[[
|CoffmanGrahamRanking| implements a node ranking algorithm based on
the Coffman--Graham scheduling algorithm, which can be used as first
phase in |SugiyamaLayout|. The aim of the algorithm is to ensure that
the height of the ranking (the number of layers) is kept small.
]]
--------------------------------------------------------------------


--------------------------------------------------------------------
key          "CoffmanGrahamRanking.width"
summary      "A mysterious width parameter..."
--------------------------------------------------------------------
