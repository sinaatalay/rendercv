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
-- @section subsection {Specifying Missing Children}
-- \label{section-gd-missing-children}
--
-- In the present section we discuss keys for specifying missing children
-- in a tree. For many certain kind of trees, in particular for binary
-- trees, there are not just ``a certain number of children'' at each
-- node, but, rather, there is a designated ``first'' (or ``left'') child
-- and a ``second'' (or ``right'') child. Even if one of these children
-- is missing and a node actually has only one child, the single child will
-- still be a ``first'' or ``second'' child and this information should
-- be taken into consideration when drawing a tree.
--
-- The first useful key for specifying missing children is
-- |missing number of children| which allows you to state how many
-- children there are, at minimum.
--
-- Once the minimum number of children has been set, we still need a way
-- of specifying ``missing first children'' or, more generally, missing
-- children that are not ``at the end'' of the list of children. For
-- this, there are three methods:
-- %
-- \begin{enumerate}
--   \item When you use the |child| syntax, you can use the |missing| key
--     with the |child| command to indicate a missing child:
--     %
-- \begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
--    \usegdlibrary{trees}}]
-- \tikz [binary tree layout, level distance=5mm]
-- \node {a}
-- child { node {b}
--   child { node {c}
--     child { node {d} }
-- } }
-- child { node {e}
--   child [missing]
--   child { node {f}
--     child [missing]
--     child { node {g}
-- } } };
-- \end{codeexample}
--     %
--   \item When using the |graph| syntax, you can use an ``empty node'',
--     which really must be completely empty and may not even contain a
--     slash, to indicate a missing node:
--     %
-- \begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
--    \usegdlibrary{trees}}]
-- \tikz [binary tree layout, level distance=5mm]
-- \graph { a -> { b -> c -> d, e -> { , f -> { , g} } } };
-- \end{codeexample}
--     %
--   \item You can simply specify the index of a child directly using
--     the key |desired child index|.
-- \end{enumerate}
--
-- @end


-- Imports
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare



---
--
declare {
  key     = "minimum number of children",
  type    = "number",
  initial = "0",

  summary = [["
    Specifies how many children a tree node must have at least. If
    there are less, ``virtual'' children are added.
  "]],
  documentation = [["
    When this key is set to |2| or more, the following happens: We first
    compute a spanning tree for the graph, see
    Section~\ref{subsection-gd-spanning-tree}. Then, whenever a node is
    not a leaf in this spanning tree (when it has at least one child),
    we add ``virtual'' or ``dummy'' nodes as children of the node until
    the total number of real and dummy children is at least
    \meta{number}. If there where at least \meta{number} children at the
    beginning, nothing happens.

    The new children are added after the existing children. This means
    that, for instance, in a tree with \meta{number} set to |2|, for
    every node with a single child, this child will be the first child
    and the second child will be missing.
  "]],
  examples = [["
    \tikz \graph [binary tree layout,level distance=5mm]
    { a -> { b->c->d, e->f->g } };
  "]]
}

---

declare {
  key  = "desired child index",
  type = "number",

  summary = [["
    Pass this key to a node to tell the graph drawing engine which child
    number you ``desired'' for the node. Whenever all desires for the
    children of a node are conflict-free, they will all be met; children
    for which no desired indices were given will remain at their
    position, whenever possible, but will ``make way'' for children with
    a desired position.
  "]],
  documentation = [["
    In detail, the following happens: We first
    determine the total number of children (real or dummy) needed, which
    is the maximum of the actual number of children, of the
    \texttt{minimum number of children}, and of the highest desired
    child index. Then we go over all children that have a desired child
    index and put they at this position. If the position is already
    taken (because some other child had the same desired index), the
    next free position is used with a wrap-around occurring at the
    end. Next, all children without a desired index are place using the
    same mechanism, but they want to be placed at the position they had
    in the original spanning tree.

    While all of this might sound a bit complicated, the application of
    the key in a binary tree is pretty straightforward: To indicate that
    a node is a ``right'' child in a tree, just add \texttt{desired child index=2}
    to it. This will make it a second child, possibly causing the first
    child to be missing. If there are two nodes specified as children of
    a node, by saying \texttt{desired child index=}\meta{number} for one
    of them, you will cause it be first or second child, depending on
    \meta{number}, and cause the \emph{other} child to become the other
    child.

    Since |desired child index=2| is a bit long, the following shortcuts
    are available: |first|, |second|, |third|, and |fourth|.
    You might wonder why |second| is used rather than |right|. The
    reason is that trees may also grow left and right and, additionally,
    the |right| and |left| keys are already in use for
    anchoring. Naturally, you can locally redefine them, if you want.
  "]],
  examples = {[["
    \tikz \graph [binary tree layout, level distance=5mm]
    { a -> b[second] };
  "]],[["
    \tikz \graph [binary tree layout, level distance=5mm]
    { a -> { b[second], c} };
  "]],[["
    \tikz \graph [binary tree layout, level distance=5mm]
    { a -> { b, c[first]} };
  "]],[["
    \tikz \graph [binary tree layout, level distance=5mm]
    { a -> { b[second], c[second]} };
  "]],[["
    \tikz \graph [binary tree layout, level distance=5mm]
    { a -> { b[third], c[first], d} };
  "]]
  }
}


---

declare {
  key  = "first",
  use = {
    { key = "desired child index", value = 1},
  },

  summary = [["
    A shorthand for setting the desired child number to |1|.
  "]]
 }

---

declare {
  key  = "second",
  use = {
    { key = "desired child index", value = 2},
  },

  summary = [["
    A shorthand for setting the desired child number to |2|.
  "]]
 }


---

declare {
  key  = "third",
  use = {
    { key = "desired child index", value = 3},
  },

  summary = [["
    A shorthand for setting the desired child number to |3|.
  "]]
 }


---

declare {
  key  = "fourth",
  use = {
    { key = "desired child index", value = 4}
  },

  summary = [["
    A shorthand for setting the desired child number to |4|.
  "]]
 }
