-- Copyright 2010 by Renée Ahrens, Olof Frahm, Jens Kluttig, Matthias Schulz, Stephan Schuster
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
-- @section subsubsection {The ``Hello World'' of Graph Drawing}
--
-- @end


-- Inputs
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

---

declare {
  key = "simple demo layout",
  algorithm = {
    run =
      function (self)
        local g = self.digraph
        local alpha = (2 * math.pi) / #g.vertices

        for i,vertex in ipairs(g.vertices) do
          local radius = vertex.options['radius'] or g.options['radius']
          vertex.pos.x = radius * math.cos(i * alpha)
          vertex.pos.y = radius * math.sin(i * alpha)
        end
      end
  },

  summary = [["
    This algorithm is the ``Hello World'' of graph drawing.
  "]],
  documentation = [=["
    The algorithm arranges nodes in a circle (without paying heed to the
    sizes of the nodes or to the edges). In order to ``really'' layout
    nodes in a circle, use |simple necklace layout|; the present layout
    is only intended to demonstrate how much (or little) is needed to
    implement a graph drawing algorithm.
    %
\begin{codeexample}[code only, tikz syntax=false]
-- File pgf.gd.examples.SimpleDemo
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

declare {
  key = "simple demo layout",
  algorithm = {
    run =
      function (self)
        local g = self.digraph
        local alpha = (2 * math.pi) / #g.vertices

        for i,vertex in ipairs(g.vertices) do
          local radius = vertex.options['radius'] or g.options['radius']
          vertex.pos.x = radius * math.cos(i * alpha)
          vertex.pos.y = radius * math.sin(i * alpha)
        end
      end
  },
  summary = "This algorithm is the 'Hello World' of graph drawing.",
  documentation = [["
    This algorithm arranges nodes in a circle ...
  "]]
}
\end{codeexample}

    On the display layer (\tikzname, that is) the algorithm can now
    immediately be employed; you just need to say
    |\usegdlibrary{examples.SimpleDemo}| at the beginning
    somewhere.
  "]=]
}