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
-- @section subsubsection {The Distance Between Components}
--
-- Once the components of a graph have been oriented, sorted, aligned,
-- and a direction has been chosen, it remains to determine the distance
-- between adjacent components. Two methods are available for computing
-- this distance, as specified by the following option:
--
-- @end

---

declare {
  key = "component packing",
  type = "string",
  initial = "skyline",

  documentation = [["
    Given two components, their distance is computed as follows in
    dependence of \meta{method}:
    %
    \begin{itemize}
      \item \declare{|rectangular|}

        Imagine a bounding box to be drawn around both components. They
        are then shifted such that the padding (separating distance)
        between the two boxes is the current value of |component sep|.
        %
        \begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
        \tikz \graph [tree layout, nodes={draw}, component sep=0pt,
                      component packing=rectangular]
          { a -- long text, longer text -- b};
        \end{codeexample}
          %
      \item \declare{|skyline|}

        The ``skyline method'' is used to compute the distance. It works
        as follows: For simplicity, assume that the component direction is
        right (other case work similarly, only everything is
        rotated). Imaging the second  component to be placed far right
        beyond the first component. Now start moving the second component
        back to the left until one of the nodes of the second component
        touches a node of the first component, and stop. Again, the
        padding |component sep| can be used to avoid the nodes actually
        touching each other.
        %
        \begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
        \tikz \graph [tree layout, nodes={draw}, component sep=0pt,
                      level distance=1.5cm,
                      component packing=skyline]
          { a -- long text, longer text -- b};
        \end{codeexample}

        In order to avoid nodes of the second component ``passing through
        a hole in the first component'', the actual algorithm is a bit
        more complicated: For both components, a ``skyline'' is
        computed. For the first component, consider an arbitrary
        horizontal line. If there are one or more nodes on this line, the
        rightmost point on any of the bounding boxes of these nodes will
        be the point on the skyline of the first component for this
        line. Similarly, for the second component, for each horizontal
        level the skyline is given by the leftmost point on any of the
        bounding boxes intersecting the line.

        Now, the interesting case are horizontal lines that do not
        intersect any of the nodes of the first and/or second
        component. Such lines represent ``holes'' in the skyline. For
        them, the following rule is used: Move the horizontal line upward
        and downward as little as possible until a height is reached where
        there is a skyline defined. Then the skyline position on the
        original horizontal line is the skyline position at the reached
        line, minus (or, for the second component, plus) the distance by
        which the line was moved. This means that the holes are ``filled
        up by slanted roofs''.
        %
        \begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{trees}}]
        \begin{tikzpicture}
          \graph [tree layout, nodes={draw}, component sep=0pt,
                  component packing=skyline]
          { a -- long text, longer text -- b};
          \draw[red] (long text.north east) -- ++(north west:1cm);
        \end{tikzpicture}
        \end{codeexample}

    \end{itemize}
  "]]
}


return Components
