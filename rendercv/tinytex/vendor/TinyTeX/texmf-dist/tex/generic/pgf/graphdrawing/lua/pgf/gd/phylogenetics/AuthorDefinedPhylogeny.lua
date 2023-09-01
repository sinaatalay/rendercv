-- Copyright 2013 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$




local AuthorDefinedPhylogeny = {}


-- Namespace
require("pgf.gd.phylogenetics").AuthorDefinedPhylogeny = AuthorDefinedPhylogeny

-- Imports
local InterfaceToAlgorithms = require "pgf.gd.interface.InterfaceToAlgorithms"
local Direct                = require "pgf.gd.lib.Direct"

-- Shorthand:
local declare = InterfaceToAlgorithms.declare


---
declare {
  key = "phylogenetic tree by author",
  algorithm = AuthorDefinedPhylogeny,
  phase = "phylogenetic tree generation",
  phase_default = true,

  summary = [["  
    When this key is used, the phylogenetic tree must be specified
    by the author (rather than being generated algorithmically).
  "]],
  documentation = [["
    A spanning tree of the input graph will be computed first (it
    must be connected, otherwise errors will result).
    The evolutionary length of the edges must be specified through
    the use of the |length| key for each edge.
  "]],
  examples = [["
    \tikz \graph [phylogenetic tree layout] {
      a -- {
        b [>length=2] --[length=1] { c, d },
        e [>length=3]
      }
    };
  "]]
}
    


function AuthorDefinedPhylogeny:run()
  
  local spanning_tree = self.main_algorithm.digraph.options.algorithm_phases["spanning tree computation"].new {
    ugraph = self.main_algorithm.ugraph,
    events = {} -- no events
  }:run()

  local phylogenetic_tree = Direct.ugraphFromDigraph(spanning_tree)
  local lengths = self.lengths
  
  for _,a in ipairs(phylogenetic_tree.arcs) do
    lengths[a.tail][a.head] = a:options('length')
  end

  return phylogenetic_tree
end



return AuthorDefinedPhylogeny
