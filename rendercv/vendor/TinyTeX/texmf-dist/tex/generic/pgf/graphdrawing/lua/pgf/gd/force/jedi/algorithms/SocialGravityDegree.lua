-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local ForceController = require 'pgf.gd.force.jedi.base.ForceController'
local ForceCanvasDistance = require "pgf.gd.force.jedi.forcetypes.ForceCanvasDistance"
local ForceCanvasPosition = require "pgf.gd.force.jedi.forcetypes.ForceCanvasPosition"
local ForceGraphDistance = require "pgf.gd.force.jedi.forcetypes.ForceGraphDistance"
local Storage = require "pgf.gd.lib.Storage"

local SocialClass = {}

---
declare {
  key = "social degree layout",
  algorithm = SocialClass,
  postconditions = {fixed = true},

  summary = [[
    This layout uses the social gravity algorithm proposed by Bannister
    with closeness mass to draw graphs.]],

  documentation = [[
    Bannister et all described a social gravity algorithm that can be
    implemented with different kinds of gravity.
    It is described in:
    %
    \begin{itemize}
      \item
        Michael J.~ Bannister and David Eppstein and Michael T~. Goodrich and
        Lowell Trott,
        \newblock Force-Directed Graph Drawing Using Social Gravity and Scaling,
        \newblock \emph{CoRR,} abs/1209.0748, 2012.
    \end{itemize}
    %
    This implementation uses the degree mass to determine the gravity of each
    vertex. There are three forces in this algorithm: A spring force as
    attractive force between vertices connected by an edge, an electric force as
    repulsive force between all vertex pairs, and a gravitational force pulling
    all vertices closer to their midpoint. The gravitational force depends on
    the social mass of a vertex, which can be determined in different ways. This
    algorithm uses the degree of each vertex as its mass. The gravitational
    force leads to more "important" vertices ending up closer to the middle of
    the drawing, since the social mass of a vertex is proportional to its
    importance. The social layouts work especially well on unconnected graphs
    like forests. This layout was implemented by using the Jedi framework.
  ]],

  example = 
  [[
    \tikz
      \graph[social degree layout, speed = 0.9, gravity = 0.2, node distance = 0.65cm, nodes={as=,circle, draw, inner sep=3pt,outer sep=0pt}, find equilibrium = true, maximum step = 5]{
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

  example =
  [[
    \tikz
      \graph[social degree layout, speed = 0.35, node distance = 0.7cm, maximum step = 15, nodes={as=,circle, draw, inner sep=3pt,outer sep=0pt}, radius = 1cm, gravity = 0.2]{
        a -- {a1 -- a2, a3},
        b -- {b1, b2 -- b3 -- b4 --{b5, b6}},
        c -- {c1--c2},
        d -- {d1, d2, d3 -- {d4, d5}, d6 --{d7, d8}}
      };
  ]]
}

---
declare {
  key = "gravity",
  type = "number",
  initial = 0.2,

  summary = "The gravity key describes the magnitude of the gravitational force.",

  documentation = [[
    This parameter currently only affects the \lstinline{social degree layout}
    and the \lstinline{social closeness layout}. The gravity key determines the
    strength used to pull the vertices to the center of the canvas.
  ]],

  example =
  [[
    \tikz
      \graph[social degree layout, iterations = 100, maximum time = 100, maximum step = 10]{
        a1[weight = 2] -- {a2, a3, a4, a5},
        b1 -- {b2 -- {b3, b4}, b5}
      };
  ]],

  example = [[
    \tikz
      \graph[social degree layout, iterations = 100, maximum time = 100, gravity = 0.5, maximum step = 10]{
        a1 -- {a2 [mass = 2], a3, a4, a5},
        b1 -- {b2 -- {b3, b4}, b5}
      };
  ]]
}




-- Implementation starts here:

-- define time functions
local time_fun_1, time_fun_2, time_fun_3

function time_fun_1 (t_total, t_now)
  if t_now > 3*t_total/4 then
    return t_now/t_total
  end
  return 0
end

function time_fun_3 (t_total, t_now)
  if t_now >= t_total/2 then
    return 2
  else
    return 1
  end
end

-- define table to store variables if needed
local fw_attributes = Storage.newTableStorage()

function SocialClass:run()
  --initialize masses
  local tmp
  for _, vertex in ipairs(self.ugraph.vertices) do
    tmp =  fw_attributes[vertex]
    tmp.social_mass = #self.ugraph:incoming(vertex)
  end

  -- add options to storage table
  fw_attributes.options = self.ugraph.options

  -- generate new force class
  local social_gravity = ForceController.new(self.ugraph, fw_attributes)

  -- add all required forces
  social_gravity:addForce{
    force_type = ForceCanvasDistance,
    fun_u      = function (data) return 4*data.k/(data.d*data.d) end,
    time_fun   = time_fun_2,
    epoch     = {"after expand", "during expand"}
  }
  social_gravity:addForce{
    force_type = ForceCanvasPosition,
    fun_u      = function (data) return data.attributes[data.u].social_mass*data.attributes.options.gravity end,
    time_fun   = time_fun_1,
    epoch     = {"after expand", "during expand"}
  }
  social_gravity:addForce{
    force_type = ForceGraphDistance,
    fun_u      = function (data) return -data.d/(data.k*data.k) end,
    n          = 1,
    time_fun   = time_fun_3,
    epoch     = {"after expand", "during expand"}
  }

  -- run algorithm
  social_gravity:run()
end

return SocialClass