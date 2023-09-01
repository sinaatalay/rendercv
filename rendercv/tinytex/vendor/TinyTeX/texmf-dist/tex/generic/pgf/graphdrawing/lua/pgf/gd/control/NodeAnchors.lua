-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

local declare        = require "pgf.gd.interface.InterfaceToAlgorithms".declare



---
-- @section subsection {Anchoring Edges}
--
-- \label{section-gd-anchors}
--
-- When a graph has been laid out completely, the edges between the
-- nodes must be drawn. Conceptually, an edge is ``between two
-- nodes'', but when we actually draw the node, we do not really want
-- the edge's path to start ``in the middle'' of the node; rather, we
-- want it to start ``on the border'' and also end there.
--
-- Normally, computing such border positions for nodes is something we
-- would leave to the so-called display layer (which is typically
-- \tikzname\ and \tikzname\ is reasonably good at computing border
-- positions). However, different display layers may behave
-- differently here and even \tikzname\ fails when the node shapes are
-- very involved and the paths also.
--
-- For these reasons, computing the anchor positions where edges start
-- and end is done inside the graph drawing system. As a user, you
-- specify a |tail anchor| and a |head anchor|, which are points
-- inside the tail and head nodes, respectively. The edge path will
-- then start and end at these points, however, they will usually be
-- shortened so that they actually start and end on the intersection
-- of the edge's path with the nodes' paths.


---

declare {
  key = "tail anchor",
  type = "string",
  initial = "",

  summary = [["
    Specifies where in the tail vertex the edge should start.
  "]],

  documentation = [["
    This is either a string or a number, interpreted as an angle
    (with 90 meaning ``up''). If it is a string, when the start of
    the edge is computed, we try to look up the anchor in the tail
    vertex's table of anchors (some anchors get installed in this
    table by the display system). If it is not found, we test
    whether it is one of the special ``direction anchors'' like
    |north| or |south east|. If so, we convert them into points on
    the border of the node that lie in the direction of a line
    starting at the center to a point on the bounding box of the
    node in the designated direction. Finally, if the anchor is a
    number, we use a point on the border of the node that is on a
    line from the center in the specified direction.

    If the anchor is set to the empty string (which is the default),
    the anchor is interpreted as the |center| anchor inside the
    graph drawing system. However, a display system may choose to
    make a difference between the |center| anchor and an empty
    anchor (\tikzname\ does: for options like |bend left| if the
    anchor is empty, the bend line starts at the border of the node,
    while for the anchor set explicitly to |center| it starts at the
    center).

    Note that graph drawing algorithms need not take the
    setting of this option into consideration. However, the final
    rendering of the edge will always take it into consideration
    (only, the setting may not be very sensible if the algorithm
    ignored it).
  "]]
}

---

declare {
  key = "head anchor",
  type = "string",
  initial = "",

  summary = "See |tail anchor|"
}


---

declare {
  key = "tail cut",
  type = "boolean",
  initial = true,

  summary = [["
    Decides whether the tail of an edge is ``cut'', meaning
    that the edge's path will be shortened at the beginning so that
    it starts only of the node's border rather than at the exact
    position of the |tail anchor|, which may be inside the node.
  "]]
}


---

declare {
  key = "head cut",
  type = "boolean",
  initial = true,

  summary = "See |tail cut|."
}


---

declare {
  key = "cut policy",
  type = "string",
  initial = "as edge requests",

  summary = "The policy for cutting edges entering or leaving a node.",

  documentation = [["
    This option is important for nodes only. It can have three
    possible values:
    %
    \begin{itemize}
      \item |as edge requests| Whether or not an edge entering or
        leaving the node is cut depends on the setting of the edge's
        |tail cut| and |head cut| options. This is the default.
      \item |all| All edges entering or leaving the node are cut,
        regardless of the edges' cut values.
      \item |none| No edge entering or leaving the node is cut,
        regardless of the edges' cut values.
    \end{itemize}
  "]]
}


---
declare {
  key = "allow inside edges",
  type = "boolean",
  initial = "true",

  summary = "Decides whether an edge between overlapping nodes should be drawn.",

  documentation = [["
    If two vertices overlap, it may happen that when you draw an
    edge between them, this edges would be completely inside the two
    vertices. In this case, one could either not draw them or one
    could draw a sort of ``inside edge''.
  "]],

  examples = { [["
    \tikz \graph [no layout, nodes={draw, minimum size=20pt}] {
      a [x=0, y=0] -- b [x=15pt, y=10pt] -- c[x=40pt]
    };
  "]],[["
    \tikz \graph [no layout, nodes={draw, minimum size=20pt},
                  allow inside edges=false] {
      a [x=0, y=0] -- b [x=15pt, y=10pt] -- c[x=40pt]
    };
  "]]
  }
}