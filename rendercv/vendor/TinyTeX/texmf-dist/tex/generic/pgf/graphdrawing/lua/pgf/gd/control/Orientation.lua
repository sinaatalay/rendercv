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
-- @section subsection {Orienting a Graph}
--
-- \label{subsection-library-graphdrawing-standard-orientation}
--
-- Just as a graph drawing algorithm cannot know \emph{where} a graph
-- should be placed on a page, it is also often unclear which
-- \emph{orientation} it should have. Some graphs, like trees, have a
-- natural direction in which they ``grow'', but for an ``arbitrary''
-- graph the ``natural orientation'' is, well, arbitrary.
--
-- There are two ways in which you can specify an orientation: First,
-- you can specify that the line from a certain vertex to another
-- vertex should have a certain slope. How these vertices and slopes
-- are specified in explained momentarily. Second, you can specify a
-- so-called ``growth direction'' for trees.
--
-- @end


-- Namespace
require("pgf.gd.control").Orientation = Orientation



-- Imports
local declare    = require "pgf.gd.interface.InterfaceToAlgorithms".declare


---

declare {
  key = "orient",
  type = "direction",
  default = 0,

  summary = [["
    This key specifies that the straight line from the |orient tail| to
    the |orient head| should be at an angle of \meta{direction} relative to
    the right-going $x$-axis. Which vertices are used as tail an head
    depends on where the |orient| option is encountered: When used with
    an edge, the tail is the edge's tail and the head is the edge's
    head. When used with a node, the tail or the head must be specified
    explicitly and the node is used as the node missing in the
    specification. When used with a graph as a whole, both the head and
    tail nodes must be specified explicitly.
  "]],
  documentation = [["
    Note that the \meta{direction} is independent of the actual to-path
    of an edge, which might define a bend or more complicated shapes. For
    instance, a \meta{angle} of |45| requests that the end node is ``up
    and right'' relative to the start node.

    You can also specify the standard direction texts |north| or |south east|
    and so forth as \meta{direction} and also |up|, |down|, |left|, and
    |right|. Also, you can specify |-| for ``right'' and \verb!|! for ``down''.
  "]],
  examples = {[["
    \tikz \graph [spring layout]
    {
      a -- { b, c, d, e -- {f, g, h} };
      h -- [orient=30] a;
    };
  "]],[["
    \tikz \graph [spring layout]
    {
      a -- { b, c, d[> orient=right], e -- {f, g, h} };
      h -- a;
    };
  "]]
  }
}


---

declare {
  key = "orient'",
  type = "direction",
  default = 0,

  summary = [["
    Same as |orient|, only the rest of the graph should be
    flipped relative to the connection line.
  "]],
  examples = [["
    \tikz \graph [spring layout]
    {
      a -- { b, c, d[> orient'=right], e -- {f, g, h} };
      h -- a;
    };
  "]]
}

---

declare {
  key = "orient tail",
  type = "string",

  summary = [["
    Specifies the tail vertex for the orientation of a graph. See
    |orient| for details.
  "]],
  examples = {[["
    \tikz \graph [spring layout] {
      a [orient=|, orient tail=f] -- { b, c, d, e -- {f, g, h} };
      { h, g } -- a;
    };
  "]],[["
    \tikz \graph [spring layout] {
      a [orient=down, orient tail=h] -- { b, c, d, e -- {f, g, h} };
      { h, g } -- a;
    };
  "]]
  }
}





---

declare {
  key = "orient head",
  type = "string",

  summary = [["
    Specifies the head vertex for the orientation of a graph. See
    |orient| for details.
  "]],
  examples = {[["
    \tikz \graph [spring layout]
    {
      a [orient=|, orient head=f] -- { b, c, d, e -- {f, g, h} };
      { h, g } -- a;
    };
  "]],[["
    \tikz \graph [spring layout] { a -- b -- c -- a };
    \tikz \graph [spring layout, orient=10,
                  orient tail=a, orient head=b] { a -- b -- c -- a };
  "]]
  }
}

---

declare {
  key = "horizontal",
  type = "string",

  summary = [["
    A shorthand for specifying |orient tail|, |orient head| and
    |orient=0|. The tail will be everything before the part ``| to |''
    and the head will be everything following it.
  "]],
  examples = [["
    \tikz \graph [spring layout]                    { a -- b -- c -- a };
    \tikz \graph [spring layout, horizontal=a to b] { a -- b -- c -- a };
  "]]
}




---

declare {
  key = "horizontal'",
  type = "string",

  summary = [["
    Like |horizontal|, but with a flip.
  "]]
}







---

declare {
  key = "vertical",
  type = "string",

  summary = [["
    A shorthand for specifying |orient tail|, |orient head| and |orient=-90|.
  "]],
  examples = [["
    \tikz \graph [spring layout]                  { a -- b -- c -- a };
    \tikz \graph [spring layout, vertical=a to b] { a -- b -- c -- a };
  "]]
}





---

declare {
  key = "vertical'",
  type = "string",

  summary = [["
    Like |vertical|, but with a flip.
  "]]
}



---

declare {
  key = "grow",
  type = "direction",

  summary = [["
    This key specifies in which direction the neighbors of a node
    ``should grow''. For some graph drawing algorithms, especially for
    those that layout trees, but also for those that produce layered
    layouts, there is a natural direction in which the ``children'' of
    a node should be placed. For instance, saying |grow=down| will cause
    the children of a node in a tree to be placed in a left-to-right
    line below the node (as always, you can replace the \meta{angle}
    by direction texts). The children are requested to be placed in a
    counter-clockwise fashion, the |grow'| key will place them in a
    clockwise fashion.
  "]],
  documentation = [["
    Note that when you say |grow=down|, it is not necessarily the case
    that any particular node is actually directly below the current
    node; the key just requests that the direction of growth is downward.

    In principle, you can specify the direction of growth for each node
    individually, but do not count on graph drawing algorithms to
    honor these wishes.

    When you give the |grow=right| key to the graph as a whole, it will
    be applied to all nodes. This happens to be exactly what you want:
  "]],
  examples = {[["
    \tikz \graph [layered layout, sibling distance=5mm]
    {
      a [grow=right] -- { b, c, d, e -- {f, g, h} };
      { h, g } -- a;
    };
  "]],[["
    \tikz \graph [layered layout, grow=right, sibling distance=5mm]
    {
      a -- { b, c, d, e -- {f, g, h} };
      { h, g } -- a;
    };
  "]],[["
    \tikz
      \graph [layered layout, grow=-80]
      {
        {a,b,c} --[complete bipartite] {e,d,f}
                --[complete bipartite] {g,h,i};
      };
  "]]
  }
}


---

declare {
  key = "grow'",
  type = "direction",

  summary = "Same as |grow|, only with the children in clockwise order.",
  examples = [["
    \tikz \graph [layered layout, sibling distance=5mm]
    {
      a [grow'=right] -- { b, c, d, e -- {f, g, h} };
      { h, g } -- a;
    };
  "]]
}


-- Done

return Orientation