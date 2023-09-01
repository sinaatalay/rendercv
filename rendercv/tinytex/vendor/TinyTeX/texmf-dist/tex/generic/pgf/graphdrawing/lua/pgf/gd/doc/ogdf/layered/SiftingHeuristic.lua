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
key           "SiftingHeuristic"
summary       "The sifting heuristic for 2-layer crossing minimization."
--------------------------------------------------------------------


--------------------------------------------------------------------
key           "SiftingHeuristic.strategy"
summary       "Sets a so-called ``sifting strategy''."
documentation
[[
  The following values are permissible: |left_to_right|, |desc_degree|,
  and |random|.
]]
--------------------------------------------------------------------
