-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Imports
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare


---
-- @section subsection {Controlling and Configuring Force-Based Algorithms}
--
-- All force-based algorithms are based on
-- a general pattern which we detail in the following. Numerous options
-- can be used to influence the behavior of this general pattern; more
-- specific options that apply only to individual algorithms are
-- explained along with these algorithms.
--
-- The vertices are initially laid out in a random configuration.
-- Then the configuration is annealed to find a configuration of
-- minimal energy.  To avoid getting stuck in a local minimum or at a
-- saddle point, random forces are added.  All of this makes the final
-- layout extremely susceptible to changes in the random numbers.  To
-- achieve a certain stability of the results, you should fix the
-- random seed.  However, in the recent past Lua has switched its
-- random number generator, which means that you won't get the same
-- sequence of random numbers as in a previous version, even for
-- identical seed.  If you rely on the long-term stability of vertex
-- placement, you should consider using a different layout.  With the
-- spring layout you have to assume that the layout will be random.
--
-- @end


