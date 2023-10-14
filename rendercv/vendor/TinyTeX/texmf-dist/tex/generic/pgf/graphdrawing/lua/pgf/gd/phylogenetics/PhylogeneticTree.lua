-- Copyright 2013 by Sarah Mäusle and Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local PhylogeneticTree = {}


-- Namespace
require("pgf.gd.phylogenetics").PhylogeneticTree = PhylogeneticTree

-- Imports
local InterfaceToAlgorithms = require "pgf.gd.interface.InterfaceToAlgorithms"
local Storage               = require "pgf.gd.lib.Storage"
local Direct                = require "pgf.gd.lib.Direct"

-- Shorthand:
local declare = InterfaceToAlgorithms.declare


---
declare {
  key = "phylogenetic tree layout",
  algorithm = PhylogeneticTree,

  postconditions = {
    upward_oriented = true
  },

  summary = [["
    Layout for drawing phylogenetic trees.
  "]],
  documentation = [["
    ...
  "]],
  examples = [["
    \tikz \graph [phylogenetic tree layout, upgma,
                  distance matrix={
                    0 4 9 9 9 9 9
                    4 0 9 9 9 9 9
                    9 9 0 2 7 7 7
                    9 9 2 0 7 7 7
                    9 9 7 7 0 3 5
                    9 9 7 7 3 0 5
                    9 9 7 7 5 5 0}]
      { a, b, c, d, e, f, g };
  "]]
}


-- Computes a phylogenetic tree and/or visualizes it
-- - computes a phylogenetic tree according to what the "phylogenetic
-- algorithm" key is set to
-- - invokes a graph drawing algorithm according to what the
-- "phylogenetic layout" key is set to
function PhylogeneticTree:run()

  local options = self.digraph.options

  -- Two storages for some information computed by the phylogenetic
  -- tree generation algorithm
  local lengths   = Storage.newTableStorage()

  -- First, compute the phylogenetic tree
  local tree = options.algorithm_phases['phylogenetic tree generation'].new {
    main_algorithm = self,
    lengths        = lengths
  }:run()

  tree = Direct.ugraphFromDigraph(tree)

  -- Second, layout the tree
  local layout_class = options.algorithm_phases['phylogenetic tree layout']
  layout_class.new {
    main_algorithm = self,
    distances      = distances,
    lengths        = lengths,
    tree           = tree
  }:run()

  tree:sync()
end

return PhylogeneticTree
