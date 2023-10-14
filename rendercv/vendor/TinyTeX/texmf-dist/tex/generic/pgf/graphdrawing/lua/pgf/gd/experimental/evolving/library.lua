-- Copyright 2016 by Malte Skambath
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information



-- @library

local evolving -- Library name

-- Load dependencies:
require "pgf.gd.trees.ChildSpec"
require "pgf.gd.trees.ReingoldTilford1981"
require "pgf.gd.layered"

-- Load declarations from:
require "pgf.gd.experimental.evolving.TimeSpec"
require "pgf.gd.experimental.evolving.Supergraph"

-- Load preprocessing/optimization phases from:
require "pgf.gd.experimental.evolving.SupergraphVertexSplitOptimization"
require "pgf.gd.experimental.evolving.GreedyTemporalCycleRemoval"

-- Load postprocessing/graph animation phases from:
require "pgf.gd.experimental.evolving.GraphAnimationCoordination"

-- Load algorithms from:
require "pgf.gd.experimental.evolving.Skambath2016"
