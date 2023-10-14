-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

local HuClass = {}

-- Imports
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local ForceController = require "pgf.gd.force.jedi.base.ForceController"
local ForceCanvasDistance = require "pgf.gd.force.jedi.forcetypes.ForceCanvasDistance"
local ForceGraphDistance = require "pgf.gd.force.jedi.forcetypes.ForceGraphDistance"

---
declare {
  key = "jedi spring electric layout",
  algorithm = HuClass,
  documentation_in = "documentation_hu_layout",
  preconditions = { connected = true },
  postconditions = {fixed = true},

  summary = "This layout uses the spring electric algorithm proposed by Hu to draw graphs.",

  documentation = [[
    The spring electric algorithm by Hu uses two kinds of forces and coarsening.
    It is described in:
    %
    \begin{itemize}
      \item
        Yifan Hu,
        \newblock Efficient, high quality force-directed graph drawing,
        \newblock \emph{The Mathematica Journal,}
        10(1), 37--71, 2006.
    \end{itemize}
    %
    This algorithm uses spring forces as attractive forces between vertices
    connected by an edge and electric forces as repulsive forces between
    all vertex pairs. Hu introduces coarsening, a procedure which repeatedly
    merges vertices in order to obtain a smaller version of the graph, to
    overcome local minima. He also uses the Barnes-Hut algorithm to enhance
    the runtime of his algorithms. This algorithm is not used in this
    implementation. This layout was implemented by using the Jedi framework.
  ]],

  example =
  [[
  \tikz
    \graph[spring electric fw layout, speed = 0.35, node distance = 5cm, nodes={as=,circle, draw, inner sep=3pt,outer sep=0pt}, maximum displacement per step = 10]{
      a -- {b, c, d, e},
      b -- {c, d, e},
      c -- {d, e},
      d --e
    };
  ]],

  example =
  [[
  \tikz
    \graph[spring electric fw layout, speed = 0.35, node distance = 1cm, horizontal = c to l, nodes={as=,circle, draw, inner sep=3pt,outer sep=0pt}, maximum displacement per step = 10]{
      a -> b -> c -> {d1 -> e  -> f -> g -> h -> i -> {j1 -> e, j2 -> l}, d2 -> l -> m}, m -> a
    };
  ]]
}




-- Implementation starts here:

function HuClass:run()
  -- Generate new force class
  local hu = ForceController.new(self.ugraph)

  -- add all required forces
  hu:addForce{
    force_type = ForceCanvasDistance,
    fun_u      = function (data) return (data.k*data.k)/data.d end,
    epoch      = {"during expand", "after expand"}
  }
  hu:addForce{
    force_type = ForceGraphDistance,
    fun_u      = function (data) return -(data.d*data.d)/data.k end,
    n          = 1,
    epoch      = {"during expand", "after expand"}
  }

  -- run algorithm
  hu:run()
end

return HuClass