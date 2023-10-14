-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

local SocialClass = {}

--Imports
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local ForceController = require 'pgf.gd.force.jedi.base.ForceController'
local ForceCanvasDistance = require "pgf.gd.force.jedi.forcetypes.ForceCanvasDistance"
local ForceCanvasPosition = require "pgf.gd.force.jedi.forcetypes.ForceCanvasPosition"
local ForceGraphDistance = require "pgf.gd.force.jedi.forcetypes.ForceGraphDistance"
local PathLengthsFW = require "pgf.gd.force.jedi.base.PathLengthsFW"
local Storage = require "pgf.gd.lib.Storage"

---
declare {
  key = "social closeness layout",
  algorithm = SocialClass,
  postconditions = {fixed = true},

  summary = [[
    This layout uses the social gravity algorithm proposed by Bannister
    with closeness mass to draw graphs.
  ]],

  documentation = [[
    Bannister et all described a social gravity algorithm that can be
    implemented with different kinds of gravity.
    It is described in:
    %
    \begin{itemize}
      \item Michael J.~ Bannister and David Eppstein and Michael T~. Goodrich
        and Lowell Trott,
        \newblock Force-Directed Graph Drawing Using Social Gravity and Scaling,
        \newblock \emph{CoRR,}
        abs/1209.0748, 2012.
    \end{itemize}
    %
    This implementation uses the closeness mass to determine the gravity of each
    vertex. There are three forces in this algorithm: A spring force as
    attractive force between vertices connected by an edge, an electric force as
    repulsive force between all vertex pairs, and a gravitational force pulling
    all vertices closer to their midpoint. The gravitational force depends on
    the social mass of a vertex, which can be determined in different ways. This
    algorithm uses the closeness mass. The closeness of a vertex $u$ is the
    reciprocal of the sum of the shortest path from $u$ to every other vertex
    $v$. The gravitational force leads to more "important" vertices ending up
    closer to the middle of the drawing, since the social mass of a vertex is
    proportional to its importance. The social layouts work especially well on
    unconnected graphs like forests. This layout was implemented by using the
    Jedi framework.
  ]],

  example = [[
    \tikz
      \graph[social closeness layout, speed = 0.9, gravity = 0.2, node distance = 0.65cm, nodes={as=,circle, draw, inner sep=3pt,outer sep=0pt}, find equilibrium = true, maximum step = 5]{
        a -- a1 -- a2 -- a,
        b -- b1 -- b2 -- b,
        c -- c1 -- c2 -- c,
        d -- d1 -- d2 -- d,
        e -- e1 -- e2 -- e,
        f -- f1 -- f2 -- f,
        g -- g1 -- g2 -- g,
        h -- h1 -- h2 -- h,
        i -- i1 -- i2 -- i,
        j -- j1 -- j2 -- j,
        a -- b -- c -- d -- e -- f -- g -- h -- i -- j -- a
      };
  ]],

  example = [[
    \tikz
      \graph[social closeness layout, speed = 0.35, node distance = 0.7cm, maximum step = 5, nodes={as=,circle, draw, inner sep=3pt,outer sep=0pt}, radius = 1cm, gravity = 2]{
        a -- {a1 -- a2, a3},
        b -- {b1, b2 -- b3 -- b4 --{b5, b6}},
        c -- {c1--c2},
        d -- {d1, d2, d3 -- {d4, d5}, d6 --{d7, d8}}
      };
  ]]
}

local fw_attributes = Storage.newTableStorage()

function SocialClass:run()
  local dist = PathLengthsFW:breadthFirstSearch(self.ugraph)
  local tmp
  for vertex, n in pairs(dist) do
    tmp =  fw_attributes[vertex]
    local sum = 0
    for i, w in pairs(n) do
      sum = sum + w
    end
    sum = sum / # self.ugraph.vertices
    tmp.mass = 1/sum
  end

  fw_attributes.options = self.ugraph.options

  --Generate new force class
  social_gravity = ForceController.new(self.ugraph, fw_attributes)

  --add all required forces
 social_gravity:addForce{
    force_type = ForceCanvasDistance,
    fun_u      = function (data) return data.k/(data.d*data.d) end,
    epoch      = {"after expand", "during expand"}
  }
  social_gravity:addForce{
    force_type = ForceCanvasPosition,
    fun_u      = function (data) return  data.attributes[data.u].mass*data.attributes.options.gravity end,
    epoch      = {"after expand", "during expand"}
  }
  social_gravity:addForce{
    force_type = ForceGraphDistance,
    fun_u      = function (data) return -data.d/(data.k*data.k) end,
    n          = 1,
    epoch      = {"after expand", "during expand"}
  }

  social_gravity:run()
end

return SocialClass
