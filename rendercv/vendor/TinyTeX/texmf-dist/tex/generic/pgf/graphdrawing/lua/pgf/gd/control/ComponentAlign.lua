-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local declare       = require "pgf.gd.interface.InterfaceToAlgorithms".declare


---
-- @section subsubsection {Aligning Components}
--
-- When components are placed next to each from left to right, it
-- is not immediately clear how the components should be aligned
-- vertically. What happens is that in each component a horizontal line is
-- determined and then all components are shifted vertically so that the
-- lines are aligned. There are different strategies for choosing these
-- ``lines'', see the description of the options described later on.
-- When the |component direction| option is used to change the direction
-- in which components are placed, it certainly make no longer sense to
-- talk about ``horizontal'' and ``vertical'' lines. Instead, what
-- actually happens is that the alignment does not consider
-- ``horizontal'' lines, but lines that go in the direction specified by
-- |component direction| and aligns them by moving components along a
-- line that is perpendicular to the line. For these reasons, let us call
-- the line in the component direction the \emph{alignment line} and a
-- line that is perpendicular to it the \emph{shift line}.
--
-- The first way of specifying through which point of a component the
-- alignment line should get is to use the option |align here|.
-- In many cases, however, you will not wish to specify an alignment node
-- manually in each component. Instead, you will use the
-- |component align| key to specify a \emph{strategy} that should be used to
-- automatically determine such a node.
--
-- Using a combination of |component direction| and |component align|,
-- numerous different packing strategies can be configured. However,
-- since names like |counterclockwise| are a bit hard to remember and to
-- apply in practice, a number of easier-to-remember keys are predefined
-- that combine an alignment and a direction.
--
-- @end

---

declare {
  key = "align here",
  type = "boolean",

  summary = [["
    When this option is given to a node, this alignment line will go
    through the origin of this node. If this option is passed to more
    than one node of a component, the node encountered first in the
    component is used.
  "]],
  examples = [["
    \tikz \graph [binary tree layout, nodes={draw}]
      { a, b -- c[align here], d -- e[second, align here] -- f };
  "]]
}

---

declare {
  key = "component align",
  type = "string",
  initial = "first node",

  summary = [["
    Specifies a ``strategy'' for the alignment of components.
  "]],
  documentation = [["
    The following values are permissible:
    %
    \begin{itemize}
      \item \declare{|first node|}

        In each component, the alignment line goes through the center of
        the first node of the component encountered during specification
        of the component.
        %
\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
\tikz \graph [binary tree layout, nodes={draw},
              component align=first node]
  { a, b -- c, d -- e[second] -- f };
\end{codeexample}
        %
      \item \declare{|center|}

        The nodes of the component are projected onto the shift line. The
        alignment line is now chosen so that it is exactly in the middle
        between the maximum and minimum value that the projected nodes
        have on the shift line.
        %
\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
\tikz \graph [binary tree layout, nodes={draw},
              component align=center]
  { a, b -- c, d -- e[second] -- f };
\end{codeexample}
        %
\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
\tikz \graph [binary tree layout, nodes={draw},
              component direction=90,
              component align=center]
  { a, b -- c, d -- e[second] -- f };
\end{codeexample}
        %
      \item \declare{|counterclockwise|}

        As for |center|, we project the nodes of the component onto the
        shift line. The alignment line is now chosen so that it goes
        through the center of the node whose center has the highest
        projected value.
        %
\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
\tikz \graph [binary tree layout, nodes={draw},
              component align=counterclockwise]
  { a, b -- c, d -- e[second] -- f };
\end{codeexample}
        %
\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
\tikz \graph [binary tree layout, nodes={draw},
              component direction=90,
              component align=counterclockwise]
 { a, b -- c, d -- e[second] -- f };
\end{codeexample}
        The name |counterclockwise| is intended to indicate that the align
        line goes through the node that comes last if we go from the
        alignment direction in a counter-clockwise direction.
      \item \declare{|clockwise|}

        Works like |counterclockwise|, only in the other direction:
        %
\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
\tikz \graph [binary tree layout, nodes={draw},
              component align=clockwise]
  { a, b -- c, d -- e[second] -- f };
\end{codeexample}
        %
\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
\tikz \graph [binary tree layout, nodes={draw},
              component direction=90,
              component align=clockwise]
  { a, b -- c, d -- e[second] -- f };
\end{codeexample}
        %
      \item \declare{|counterclockwise bounding box|}

        This method is quite similar to |counterclockwise|, only the
        alignment line does not go through the center of the node with a
        maximum projected value on the shift line, but through the maximum
        value of the projected bounding boxes. For a left-to-right
        packing, this means that the components are aligned so that the
        bounding boxes of the components are aligned at the top.
        %
\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
\tikz \graph [tree layout, nodes={draw, align=center},
              component sep=0pt,
              component align=counterclockwise]
  { a, "high\\node" -- b};\quad
\tikz \graph [tree layout, nodes={draw, align=center},
              component sep=0pt,
              component align=counterclockwise bounding box]
  { a, "high\\node" -- b};
\end{codeexample}
        %
      \item \declare{|clockwise bounding box|}

        Works like |counterclockwise bounding box|.
    \end{itemize}
  "]]
}

---

declare {
  key = "components go right top aligned",
  use = {
    { key = "component direction", value = 0},
    { key = "component align", value = "counterclockwise"},
  },

  summary = [["
    Shorthand for |component direction=right| and
    |component align=counterclockwise|. This means that, as the name
    suggest, the components will be placed left-to-right and they are
    aligned such that their top nodes are in a line.
  "]],
  examples = [["
    \tikz \graph [tree layout, nodes={draw, align=center},
                  components go right top aligned]
      { a, "high\\node" -- b};
  "]]
}

---

declare {
  key = "components go right absolute top aligned",
  use = {
    { key = "component direction", value=0},
    { key = "component align", value = "counterclockwise bounding box"},
  },

  summary = [["
    Like |components go right top aligned|, but with
    |component align| set to |counterclockwise| |bounding box|.
    This means that the components will be aligned with their bounding
    boxed being top-aligned.
  "]],
  examples = [["
    \tikz \graph [tree layout, nodes={draw, align=center},
                  components go right absolute top aligned]
      { a, "high\\node" -- b};
  "]]
}

---

declare {
  key = "components go right bottom aligned",
  use = {
    { key = "component direction", value=0},
    { key = "component align", value = "clockwise"},
  },

  summary = "See the other |components go ...| keys."
}

---
--

declare {
  key = "components go right absolute bottom aligned",
  use = {
    { key = "component direction", value=0},
    { key = "component align", value = "clockwise bounding box"},
  },

  summary = "See the other |components go ...| keys."
}


---

declare {
  key = "components go right center aligned",
  use = {
    { key = "component direction", value=0},
    { key = "component align", value = "center"},
  },

  summary = "See the other |components go ...| keys."
}


---

declare {
  key = "components go right",
  use = {
    { key = "component direction", value=0},
    { key = "component align", value = "first node"},
  },

  summary = [["
    Shorthand for |component direction=right| and
    |component align=first node|.
  "]]
 }


---

declare {
  key = "components go left top aligned",
  use = {
    { key = "component direction", value=180},
    { key = "component align", value = "clockwise"},
  },

  summary = "See the other |components go ...| keys.",

  examples = [["
    \tikz \graph [tree layout, nodes={draw, align=center},
                  components go left top aligned]
      { a, "high\\node" -- b};
  "]]
}

---
--

declare {
  key = "components go left absolute top aligned",
  use = {
    { key = "component direction", value=180},
    { key = "component align", value = "clockwise bounding box"},
  },

  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go left bottom aligned",
  use = {
    { key = "component direction", value=180},
    { key = "component align", value = "counterclockwise"},
  },

  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go left absolute bottom aligned",
  use = {
    { key = "component direction", value=180},
    { key = "component align", value = "counterclockwise bounding box"},
  },

  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go left center aligned",
  use = {
    { key = "component direction", value=180},
    { key = "component align", value = "center"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go left",
  use = {
    { key = "component direction", value=180},
    { key = "component align", value = "first node"},
  },
  summary = "See the other |components go ...| keys."
}



---

declare {
  key = "components go down right aligned",
  use = {
    { key = "component direction", value=270},
    { key = "component align", value = "counterclockwise"},
  },
  summary = "See the other |components go ...| keys.",

  examples = {[["
    \tikz \graph [tree layout, nodes={draw, align=center},
                  components go down left aligned]
      { a, hello -- {world,s} };
  "]],[["
    \tikz \graph [tree layout, nodes={draw, align=center},
                  components go up absolute left aligned]
      { a, hello -- {world,s}};
  "]]
  }
}

---
--

declare {
  key = "components go down absolute right aligned",
  use = {
    { key = "component direction", value=270},
    { key = "component align", value = "counterclockwise bounding box"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go down left aligned",
  use = {
    { key = "component direction", value=270},
    { key = "component align", value = "clockwise"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go down absolute left aligned",
  use = {
    { key = "component direction", value=270},
    { key = "component align", value = "clockwise bounding box"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go down center aligned",
  use = {
    { key = "component direction", value=270},
    { key = "component align", value = "center"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go down",
  use = {
    { key = "component direction", value=270},
    { key = "component align", value = "first node"},
  },
  summary = "See the other |components go ...| keys."
}

---
--

declare {
  key = "components go up right aligned",
  use = {
    { key = "component direction", value=90},
    { key = "component align", value = "clockwise"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go up absolute right aligned",
  use = {
    { key = "component direction", value=90},
    { key = "component align", value = "clockwise bounding box"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go up left aligned",
  use = {
    { key = "component direction", value=90},
    { key = "component align", value = "counterclockwise"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go up absolute left aligned",
  use = {
    { key = "component direction", value=90},
    { key = "component align", value = "counterclockwise bounding box"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go up center aligned",
  use = {
    { key = "component direction", value=90},
    { key = "component align", value = "center"},
  },
  summary = "See the other |components go ...| keys."
}


---
--

declare {
  key = "components go up",
  use = {
    { key = "component direction", value=90},
    { key = "component align", value = "first node"},
  },
  summary = "See the other |components go ...| keys."
}




return Components
