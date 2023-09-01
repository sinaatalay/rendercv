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
local lib           = require "pgf.gd.lib"

---
-- @section subsection {Padding and Node Distances}
--
-- \label{subsection-gd-dist-pad}
--
-- In many drawings, you may wish to specify how ``near'' two nodes should
-- be placed by a graph drawing algorithm. Naturally, this depends
-- strongly on the specifics of the algorithm, but there are a number of
-- general keys that will be used by many algorithms.
--
-- There are different kinds of objects for which you can specify
-- distances and paddings:
-- %
-- \begin{itemize}
--   \item You specify the ``natural'' distance between nodes
--     connected by an edge using |node distance|, which is also available in
--     normal \tikzname\ albeit for a slightly different purpose. However,
--     not every algorithm will (or can) honor the key; see the description
--     of each algorithm what it will ``make of this option''.
--   \item A number of graph drawing algorithms arrange nodes in layers
--     (or levels); we refer
--     to the nodes on the same layer as siblings (although, in a tree,
--     siblings are only nodes with the same parent; nevertheless we use
--     ``sibling'' loosely also for nodes that are more like ``cousins'').
--   \item When a graph consists of several connected component, many graph
--     drawing algorithms will layout these components individually. The
--     different components will then be arranged next to each other, see
--     Section~\ref{section-gd-packing} for the details, such that between
--     the nodes of any two components a padding is available.
-- \end{itemize}
--
-- @end




---

declare {
  key = "node distance",
  type = "length",
  initial = "1cm",

  summary = [["
    This is minimum distance that the centers of nodes connected by an
    edge should have. It will not always be possible to satisfy this
    desired distance, for instance in case the nodes are too big. In
    this case, the \meta{length} is just considered as a lower bound.
  "]],
  examples = [["
    \begin{tikzpicture}
      \graph [simple necklace layout,  node distance=1cm, node sep=0pt,
              nodes={draw,circle,as=.}]
      {
        1 -- 2 [minimum size=2cm] -- 3 --
        4 -- 5 -- 6 -- 7 --[orient=up] 8
      };
      \draw [red,|-|] (1.center) -- ++(0:1cm);
      \draw [red,|-|] (5.center) -- ++(180:1cm);
    \end{tikzpicture}
  "]]
}


---

declare {
  key = "node pre sep",
  type = "length",
  initial = ".333em",

  summary = [["
    This is a minimum ``padding'' or ``separation'' between the border
    of nodes connected by an edge. Thus, if nodes are so big that nodes
    with a distance of |node distance| would overlap (or
    just come with \meta{dimension} distance of one another), their
    distance is enlarged so that this distance is still satisfied.
    The |pre| means that the padding is added to the node ``at the
    front''. This make sense only for some algorithms, like for a
    simple necklace layout.
  "]],
  examples = {[["
    \tikz \graph [simple necklace layout, node distance=0cm, nodes={circle,draw}]
      { 1--2--3--4--5--1 };
  "]],[["
    \tikz \graph [simple necklace layout, node distance=0cm, node sep=0mm,
                  nodes={circle,draw}]
      { 1--2--3[node pre sep=5mm]--4--5[node pre sep=1mm]--1 };
  "]]
  }
}

---

declare {
  key = "node post sep",
  type = "length",
  initial = ".333em",

  summary = [["
    Works like |node pre sep|.
  "]]
}



---
-- @param length A length.

declare {
  key = "node sep",
  type = "length",
  use = {
    { key = "node pre sep",  value = function(v) return v/2 end },
    { key = "node post sep", value = function(v) return v/2 end },
  },
  summary = [["
    A shorthand for setting both |node pre sep| and |node post sep| to
    $\meta{length}/2$.
  "]]
}


---

declare {
  key = "level distance",
  type = "length",
  initial = "1cm",

  summary = [["
    This is minimum distance that the centers of nodes on one
    level should have from the centers of nodes on the next level. It
    will not always be possible to satisfy this desired distance, for
    instance in case the nodes are too big. In this case, the
    \meta{length} is just considered as a lower bound.
  "]],
  examples = [["
    \begin{tikzpicture}[inner sep=2pt]
      \draw [help lines] (0,0) grid (3.5,2);
      \graph [layered layout, level distance=1cm, level sep=0]
        { 1 [x=1,y=2] -- 2 -- 3 -- 1 };
      \graph [layered layout, level distance=5mm, level sep=0]
        { 1 [x=3,y=2] -- 2 -- 3 -- 1, 3 -- {4,5} -- 6 -- 3 };
    \end{tikzpicture}
  "]]
}

---
declare {
  key = "layer distance",
  type = "length",
  use = {
    { key = "level distance", value = lib.id },
  },
  summary = "An alias for |level distance|"
}

---
declare {
  key = "level pre sep",
  type = "length",
  initial = ".333em",

  summary = [["
    This is a minimum ``padding'' or ``separation'' between the border
    of the nodes on a level to any nodes on the previous level. Thus, if
    nodes are so big that nodes on consecutive levels would overlap (or
    just come with \meta{length} distance of one another), their
    distance is enlarged so that this distance is still satisfied.
    If a node on the previous level also has a |level post sep|, this
    post padding and the \meta{dimension} add up. Thus, these keys
    behave like the ``padding'' keys rather
    than the ``margin'' key of cascading style sheets.
  "]],
  examples = [["
    \begin{tikzpicture}[inner sep=2pt, level sep=0pt, sibling distance=0pt]
      \draw [help lines] (0,0) grid (3.5,2);
      \graph [layered layout, level distance=0cm, nodes=draw]
        { 1 [x=1,y=2] -- {2,3[level pre sep=1mm],4[level pre sep=5mm]} -- 5 };
      \graph [layered layout, level distance=0cm, nodes=draw]
        { 1 [x=3,y=2] -- {2,3,4} -- 5[level pre sep=5mm] };
    \end{tikzpicture}
  "]]
}

---

declare {
  key = "level post sep",
  type = "length",
  initial = ".333em",

  summary = [["
    Works like |level pre sep|.
  "]]
}

---
declare {
  key = "layer pre sep",
  type = "length",
  use = {
    { key = "level pre sep", value = lib.id },
  },
  summary = "An alias for |level pre sep|."
}

---
declare {
  key = "layer post sep",
  type = "length",
  use = {
    { key = "level post sep", value = lib.id },
  },
  summary = "An alias for |level post sep|."
}




---
-- @param length A length

declare {
  key = "level sep",
  type = "length",
  use = {
    { key = "level pre sep", value = function (v) return v/2 end },
    { key = "level post sep", value = function (v) return v/2 end },
  },

  summary = [["
    A shorthand for setting both |level pre sep| and |level post sep| to
    $\meta{length}/2$. Note that if you set |level distance=0| and
    |level sep=1em|, you get a layout where any two consecutive layers
    are ``spaced apart'' by |1em|.
  "]]
}


---
declare {
  key = "layer sep",
  type = "number",
  use = {
    { key = "level sep", value = lib.id },
  },
  summary = "An alias for |level sep|."
}


---
declare {
  key = "sibling distance",
  type = "length",
  initial = "1cm",

  summary = [["
    This is minimum distance that the centers of node should have to the
    center of the next node on the same level. As for levels, this is
    just a lower bound.
    For some layouts, like a simple necklace layout, the \meta{length} is
    measured as the distance on the circle.
  "]],
  examples = {[["
    \tikz \graph [tree layout, sibling distance=1cm, nodes={circle,draw}]
      { 1--{2,3,4,5} };
  "]],[["
    \tikz \graph [tree layout, sibling distance=0cm, sibling sep=0pt,
                  nodes={circle,draw}]
      { 1--{2,3,4,5} };
  "]],[["
    \tikz \graph [tree layout, sibling distance=0cm, sibling sep=0pt,
                  nodes={circle,draw}]
      { 1--{2,3[sibling distance=1cm],4,5} };
  "]]
  }
}


---

declare {
  key = "sibling pre sep",
  type = "length",
  initial = ".333em",

  summary = [["
    Works like |level pre sep|, only for siblings.
  "]],
  examples = [["
    \tikz \graph [tree layout, sibling distance=0cm, nodes={circle,draw},
                  sibling sep=0pt]
      { 1--{2,3[sibling pre sep=1cm],4,5} };
  "]]
}

---

declare {
  key = "sibling post sep",
  type = "length",
  initial = ".333em",

  summary = [["
      Works like |sibling pre sep|.
   "]]
 }



---
--  @param length A length

declare {
  key = "sibling sep",
  type = "length",
  use = {
    { key = "sibling pre sep", value = function(v) return v/2 end },
    { key = "sibling post sep", value = function(v) return v/2 end },
  },

  summary = [["
    A shorthand for setting both |sibling pre sep| and |sibling post sep| to
    $\meta{length}/2$.
  "]]
}






---
declare {
  key = "part distance",
  type = "length",
  initial = "1.5cm",

  summary = [["
    This is minimum distance between the centers of ``parts'' of a
    graph. What a ``part'' is depends on the algorithm.
  "]]
}


---

declare {
  key = "part pre sep",
  type = "length",
  initial = "1em",
  summary = "A pre-padding for parts."
}

---

declare {
  key = "part post sep",
  type = "length",
  initial = "1em",
  summary = "A post-padding for pars."
 }



---
--  @param length A length

declare {
  key = "part sep",
  type = "length",
  use = {
    { key = "part pre sep", value = function(v) return v/2 end },
    { key = "part post sep", value = function(v) return v/2 end },
  },

  summary = [["
    A shorthand for setting both |part pre sep| and |part post sep| to
    $\meta{length}/2$.
  "]]
}




---

declare {
  key = "component sep",
  type = "length",
  initial = "1.5em",

  summary = [["
    This is padding between the bounding boxes that nodes of different
    connected components will have when they are placed next to each
    other.
  "]],
  examples = {[["
    \tikz \graph [binary tree layout, sibling distance=4mm, level distance=8mm,
                  components go right top aligned,
                  component sep=1pt, nodes=draw]
    {
      1 -> 2 -> {3->4[second]->5,6,7};
      a -> b[second] -> c[second] -> d -> e;
      x -> y[second] -> z -> u[second] -> v;
    };
  "]],[["
    \tikz \graph [binary tree layout, sibling distance=4mm, level distance=8mm,
                  components go right top aligned,
                  component sep=1em, nodes=draw]
    {
      1 -> 2 -> {3->4[second]->5,6,7};
      a -> b[second] -> c[second] -> d -> e;
      x -> y[second] -> z -> u[second] -> v;
    };
  "]]
  }
}



---

declare {
  key = "component distance",
  type = "length",
  initial = "2cm",

  summary = [["
    This is the minimum distance between the centers of bounding
    boxes of connected components when they are placed next to each
    other. (Not used, currently.)
  "]]
}


return Distances
