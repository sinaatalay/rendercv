-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

local SpringElectricNoCoarsenClass = {}

-- Imports
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local ForceController = require "pgf.gd.force.jedi.base.ForceController"
local ForceCanvasDistance = require "pgf.gd.force.jedi.forcetypes.ForceCanvasDistance"
local ForceGraphDistance = require "pgf.gd.force.jedi.forcetypes.ForceGraphDistance"
local Storage = require "pgf.gd.lib.Storage"

---
declare {
  key = "spring electric no coarsen layout",
  algorithm = SpringElectricNoCoarsenClass,
  preconditions = { connected = true },
  postconditions = {fixed = true},

  summary = [[
    This layout uses the algorithm proposed by Fruchterman and Reingold to draw graphs."
   ]],

  documentation = [[
    The Fruchterman-Reingold algorithm is one if the oldest methods
    for force-based graph drawing. It is described in:
    %
    \begin{itemize}
      \item
        Thomas M.~J.~ Fruchterman and Edward M.~ Reingold,
        \newblock Graph Drawing by Force-directed Placement,
        \newblock \emph{Software -- practice and experience,}
        21(1 1), 1129-1164, 1991.
    \end{itemize}
    %
    Fruchterman and Reingold had to principles in graph drawing:
    %
    \begin{enumerate}
      \item Vertices connected by an edge should be drawn close to another and
      \item in general, vertices should not be drawn too close to each other.
    \end{itemize}
    %
    The spring electric no coarsen layout uses spring forces as attractive
    forces influencing vertex pairs connected by an edge and electric forces
    as repulsive forces between all vertex pairs. The original algorithm
    also contained a frame that stopped the vertices from drifting too far
    apart, but this concept was not implemented. This algorithm will not be
    affected by coarsening. This layout was implemented by using the Jedi
    framework.
  ]],

  example =
  [[
  \tikz
    \graph[spring electric no coarsen layout, speed = 0.35, node distance = 2.5cm, nodes={as=,circle, draw, inner sep=3pt,outer sep=0pt}, coarsen = true, maximum step = 1]{
      a -- {b, c, d, e, f, g, h, i, j},
      b -- {c, d, e, f, g, h, i, j},
      c -- {d, e, f, g, h, i, j},
      d -- {e, f, g, h, i, j},
      e -- {f, g, h, i, j},
      f -- {g, h, i, j},
      g -- {h, i, j},
      h -- {i, j},
      i -- j
    };
  ]],

  example =
  [[
  \graph[spring electric no coarsen layout, speed = 0.25, node distance = 0.25cm, horizontal = c to l, nodes={as=,circle, draw, inner sep=3pt,outer sep=0pt}, coarsen = false, maximum step = 1]{
      a -> b -> c -> {d1 -> e  -> f -> g -> h -> i -> {j1 -> e, j2 -> l}, d2 -> l -> m}, m -> a
    };
  ]]
}




-- Implementation starts here

--define a local time function
local time_fun_1
function time_fun_1 (t_total, t_now)
  if t_now/t_total <= 0.5 then
    return 0.5
  else
    return 2
  end
end

-- define storage table to add attributes if wanted
local fw_attributes = Storage.newTableStorage()

function SpringElectricNoCoarsenClass:run()
  -- add options to storage table
  fw_attributes.options = self.ugraph.options

  --Generate new force class
  local spring_electric_no_coarsen = ForceController.new(self.ugraph)

  spring_electric_no_coarsen:addForce{
    force_type = ForceCanvasDistance,
    fun_u      = function (data) return data.k*data.k/(data.d) end,
    time_fun   = time_fun_1,
    epoch      = {"after expand"}
  }
  spring_electric_no_coarsen:addForce{
    force_type = ForceGraphDistance,
    fun_u      = function (data) return -data.d*data.d/(data.k) end,
    n          = 1,
    epoch      = {"after expand"}
  }

  -- run algorithm
  spring_electric_no_coarsen:run()
end

return SpringElectricNoCoarsenClass