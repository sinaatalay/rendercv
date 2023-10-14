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
-- A phylogenetic tree (or network) depicts the evolutionary history
-- of species or, more generally, so called taxa. The present library
-- includes a number of algorithms for drawing phylogenetic trees.
--
-- @library

local phylogenetics -- Library name

-- Main layout:
require "pgf.gd.phylogenetics.PhylogeneticTree"

-- Phylogenetic tree drawing:
require "pgf.gd.phylogenetics.Maeusle2012"

-- Phylogenetic tree generation:
require "pgf.gd.phylogenetics.SokalMichener1958"
require "pgf.gd.phylogenetics.BalancedMinimumEvolution"
require "pgf.gd.phylogenetics.BalancedNearestNeighbourInterchange"
require "pgf.gd.phylogenetics.AuthorDefinedPhylogeny"


