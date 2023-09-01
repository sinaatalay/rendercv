-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Load declarations from:

require "pgf.gd.control.FineTune"
require "pgf.gd.control.Anchoring"
require "pgf.gd.control.Sublayouts"
require "pgf.gd.control.Orientation"
require "pgf.gd.control.Distances"
require "pgf.gd.control.Components"
require "pgf.gd.control.ComponentAlign"
require "pgf.gd.control.ComponentDirection"
require "pgf.gd.control.ComponentDistance"
require "pgf.gd.control.ComponentOrder"
require "pgf.gd.control.NodeAnchors"


local InterfaceCore  = require "pgf.gd.interface.InterfaceCore"
local declare        = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local lib            = require "pgf.gd.lib"



---

declare {
  key = "nodes behind edges",
  type = "boolean",

  summary = "Specifies, that nodes should be drawn behind the edges",
  documentation = [["
    Once a graph drawing algorithm has determined positions for the nodes,
    they are drawn \emph{before} the edges are drawn; after
    all, it is hard to draw an edge between nodes when their positions
    are not yet known. However, we typically want the nodes to be
    rendered \emph{after} or rather \emph{on top} of the edges. For
    this reason, the default behavior is that the nodes at their
    final positions are collected in a box that is inserted into the
    output stream only after the edges have been drawn -- which has
    the effect that the nodes will be placed ``on top'' of the
    edges.

    This behavior can be changed using this option. When the key is
    invoked, nodes are placed \emph{behind} the edges.
  "]],
  examples = [["
    \tikz \graph [simple necklace layout, nodes={draw,fill=white},
                  nodes behind edges]
      { subgraph K_n [n=7], 1 [regardless at={(0,-1)}] };
  "]]
}


---

declare {
  key = "edges behind nodes",
  use = {
    { key = "nodes behind edges", value = "false" },
  },

  summary = [["
    This is the default placement of edges: Behind the nodes.
  "]],
  examples = [["
    \tikz \graph [simple necklace layout, nodes={draw,fill=white},
                  edges behind nodes]
      { subgraph K_n [n=7], 1 [regardless at={(0,-1)}] };
 "]]
}

---
declare {
  key = "random seed",
  type = "number",
  initial = "42",

  summary = [["
    To ensure that the same is always shown in the same way when the
    same algorithm is applied, the random is seed is reset on each call
    of the graph drawing engine. To (possibly) get different results on
    different runs, change this value.
  "]]
}


---
declare {
  key = "variation",
  type = "number",
  use = {
    { key = "random seed", value = lib.id },
  },
  summary = "An alias for |random seed|."
}


---
declare {
  key = "weight",
  type = "number",
  initial = 1,

  summary = [["
    Sets the ``weight'' of an edge or a node. For many algorithms, this
    number tells the algorithm how ``important'' the edge or node is.
    For instance, in a |layered layout|, an edge with a large |weight|
    will be as short as possible.
  "]],
  examples = {[["
    \tikz \graph [layered layout] {
      a -- {b,c,d} -- e -- a;
    };
  "]],[["
    \tikz \graph [layered layout] {
      a -- {b,c,d} -- e --[weight=3] a;
    };
 "]]
  }
}



---
declare {
  key = "length",
  type = "length",
  initial = 1,

  summary = [["
    Sets the ``length'' of an edge. Algorithms may take this value
    into account when drawing a graph.
  "]],
  examples = {[["
    \tikz \graph [phylogenetic tree layout] {
      a --[length=2] b --[length=1] {c,d};
      a --[length=3] e
    };
  "]],
  }
}


---

declare {
  key = "radius",
  type = "number",
  initial = "0",

  summary = [["
    The radius of a circular object used in graph drawing.
  "]]
}

---

declare {
  key = "no layout",
  algorithm = {
    run =
      function (self)
        for _,v in ipairs(self.digraph.vertices) do
          if v.options['desired at'] then
            v.pos.x = v.options['desired at'].x
            v.pos.y = v.options['desired at'].y
          end
        end
      end },
  summary = "This layout does nothing.",
}



-- The following collection kinds are internal

declare {
  key = InterfaceCore.sublayout_kind,
  layer = 0
}

declare {
  key = InterfaceCore.subgraph_node_kind,
  layer = 0
}

