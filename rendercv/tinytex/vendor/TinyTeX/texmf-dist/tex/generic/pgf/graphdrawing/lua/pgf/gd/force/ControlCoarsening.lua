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
-- @section subsubsection {Coarsening}
--
-- @end


---

declare {
  key = "coarsen",
  type = "boolean",
  initial = "true",

  summary = [["
    Defines whether or not a multilevel approach is used that
    iteratively coarsens the input graph into graphs $G_1,\dots,G_l$
    with a smaller and smaller number of nodes. The coarsening stops as
    soon as a minimum number of nodes is reached, as set via the
    |minimum coarsening size| option, or if, in the last iteration, the
    number of nodes was not reduced by at least the ratio specified via
    |downsize ratio|.
  "]],
  documentation = [["
    A random initial layout is computed for the coarsest graph $G_l$ first.
    Afterwards, it is laid out by computing the attractive and repulsive
    forces between its nodes.

    In the subsequent steps, the previous coarse graph $G_{l-1}$ is
    restored and its node positions are interpolated from the nodes
    in~$G_l$. The graph $G_{l-1}$ is again laid out by computing the forces
    between its nodes. These steps are repeated with $G_{l-2},\dots,G_1$ until
    the original input graph $G_0$ has been restored, interpolated
    and laid out.

    The idea behind this approach is that, by arranging recursively
    formed supernodes first and then interpolating and arranging their
    subnodes step by step, the algorithm is less likely to settle in a
    local energy minimum (of which there can be many, particularly for
    large graphs). The quality of the drawings with coarsening enabled is
    expected to be higher than graphics where this feature is not applied.

    The following example demonstrates how coarsening can improve the
    quality of graph drawings generated with Walshaw's algorihtm
    |spring electrical layout'|.
  "]],
  examples = [["
    \tikz \graph [spring electrical layout', coarsen=false, vertical=3 to 4]
      {
        { [clique] 1, 2 } -- 3 -- 4 -- { 5, 6, 7 }
      };

    \tikz \graph [spring electrical layout', coarsen, vertical=3 to 4]
      {
        { [clique] 1, 2 } -- 3 -- 4 -- { 5, 6, 7 }
      };
  "]]
}

---

declare {
  key = "minimum coarsening size",
  type = "number",
  initial = 2,

  summary = [["
    Defines the minimum number of nodes down to which the graph is
    coarsened iteratively. The first graph that has a smaller or equal
    number of nodes becomes the coarsest graph $G_l$, where $l$ is the
    number of coarsening steps. The algorithm proceeds with the steps
    described in the documentation of the |coarsen| option.
  "]],
  documentation = [["
    In the following example the same graph is coarsened down to two
    and four nodes, respectively. The layout of the original graph is
    interpolated from the random initial layout and is not improved
    further because the forces are not computed (0 iterations). Thus,
    in the two graphs, the nodes are placed at exactly two and four
    coordinates in the final drawing.
  "]],
  examples = [["
    \tikz \graph [spring layout, iterations=0,
                  minimum coarsening size=2]
      { subgraph C_n [n=8] };

    \tikz \graph [spring layout, iterations=0,
                  minimum coarsening size=4]
      { subgraph C_n [n=8] };
  "]]
}

---

declare {
  key = "downsize ratio",
  type = "number",
  initial = "0.25",

  summary = [["
    Minimum ratio between 0 and 1 by which the number of nodes between
    two coarse graphs $G_i$ and $G_{i+1}$ need to be reduced in order for
    the coarsening to stop and for the algorithm to use $G_{i+1}$ as the
    coarsest graph $G_l$. Aside from the input graph, the optimal value
    of |downsize ratio| mostly depends on the coarsening scheme being
    used. Possible schemes are |collapse independent edges| and
    |connect independent nodes|.
  "]],
  documentation = [["
    Increasing this option possibly reduces the number of coarse
    graphs computed during the coarsening phase as coarsening will stop as
    soon as a coarse graph does not reduce the number of nodes
    substantially. This may speed up the algorithm but if the size of the
    coarsest graph $G_l$ is much larger than |minimum coarsening size|, the
    multilevel approach may not produce drawings as good as with a lower
    |downsize ratio|.
  "]],
  examples = [["
    % 1. ratio too high, coarsening stops early, benefits are lost
    \tikz \graph [spring electrical layout',
                  downsize ratio=1.0,
                  node distance=7mm, vertical=3 to 4]
      { { [clique] 1, 2 } -- 3 -- 4 -- { 5, 6, 7 } };

    % 2. ratio set to default, coarsening benefits are visible
    \tikz \graph [spring electrical layout',
                  downsize ratio=0.2,
                  node distance=7mm, vertical=3 to 4]
      { { [clique] 1, 2 } -- 3 -- 4 -- { 5, 6, 7 } };
  "]]
}

