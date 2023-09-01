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
-- @section subsubsection {The Iterative Process and Cooling}
--
-- @end



---

declare {
  key     = "iterations",
  type    = "number",
  initial = "500",

  summary = [["
    Limits the number of iterations of algorithms for force-based
    layouts to \meta{number}.
  "]],
  documentation = [["
    Depending on the characteristics of the input graph and the parameters
    chosen for the algorithm, minimizing the system energy may require
    many iterations.

    In these situations it may come in handy to limit the number of
    iterations. This feature can also be useful to draw the same graph
    after different iterations and thereby demonstrate how the spring or
    spring-electrical algorithm improves the drawing step by step.

    The examples shows two drawings generated using two
    different |iteration| limits.
  "]],
  examples = {[["
    \tikz \graph [spring layout, iterations=10]  { subgraph K_n [n=4] };
  "]],[["
    \tikz \graph [spring layout, iterations=500] { subgraph K_n [n=4] };
  "]],[["
    \tikz \graph [spring electrical layout, iterations=10]
      { subgraph K_n [n=4] };
  "]],[["
    \tikz \graph [spring electrical layout, iterations=500]
      { subgraph K_n [n=4] };
  "]]
  }
}

---

declare {
  key     = "initial step length",
  type    = "length",
  initial = "0",

  summary = [["
    This parameter specifies the amount by which nodes will be
    displaced in each iteration, initially. If set to |0| (which is the
    default), an appropriate value is computed automatically.
  "]]
  }

---

declare {
  key  = "cooling factor",
  type = "number",
  initial = "0.95",

  summary = [["
    This parameter helps in controlling how layouts evolve over
    time. It is used to gradually reduce the step size
    between one iteration to the next.
  "]],
  documentation = [["
    A small positive cooling factor
    $\ge 0$ means that the movement of nodes is quickly or abruptly
    reduced, while a large cooling factor $\le 1$ allows for a smoother
    step by step layout refinement at the cost of more iterations. The
    following example demonstrates how a smaller cooling factor may
    result in a less balanced drawing. By default, Hu2006 spring,
    Hu2006 spring electrical, and Walshaw2000 spring electrical use a
    cooling factor of |0.95|.
  "]],
  examples = {[["
    \tikz \graph [spring layout, cooling factor=0.1]
      { a -> b -> c -> a };
  "]],[["
    \tikz \graph [spring layout, cooling factor=0.5]
      { a -> b -> c -> a };
  "]]
  }
}

---

declare {
  key = "convergence tolerance",
  type = "number",
  initial = "0.01",

  summary = [["
      All spring and spring-electrical algorithms implemented in the
      thesis terminate as soon as the maximum movement of any node drops
      below $k \cdot \meta{tolerance}$. This tolerance factor can be changed
      with the convergence tolerance option:
  "]],
  examples = {[["
    \tikz \graph [spring layout, convergence tolerance=0.001]
      { { [clique] 1, 2 } -- 3 -- 4 -- { 5, 6, 7 } };
  "]],[["
    \tikz \graph [spring layout, convergence tolerance=1.0]
      { { [clique] 1, 2 } -- 3 -- 4 -- { 5, 6, 7 } };
  "]]
  }
}





