-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

local SimpleSpringClass = {}

-- Imports
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local ForceController = require 'pgf.gd.force.jedi.base.ForceController'
local ForceGraphDistance = require "pgf.gd.force.jedi.forcetypes.ForceGraphDistance"

---
declare {
  key = "trivial spring layout",
  algorithm = SimpleSpringClass,
  documentation_in = "pgf.gd.doc.jedi.algorithms.SimpleSpringLayout",
  preconditions = { connected = true },
  postconditions = {fixed = true},

  summary = "This layout uses only spring forces to draw graphs.",

  documentation = [[
    The simple spring algorithm only uses one force kind: A spring force
    that serves as both attractive and repulsive force. The edges are modeled as
    springs and act according to Hoke's law: They have an ideal length and will
    expand if they are contracted below this length, pushing the adjacent
    vertices away from each other, and contract if it is stretched, pulling the
    adjacent vertices towards each other. This ideal length is given by the
    parameter |node distance|. There is no force repelling vertices that are not
    connected to each other, which can lead to vertices being placed at the same
    point. It is not a very powerful layout and will probably fail with large
    graphs, especially if they have few edges. It can however be used to
    demonstrate the effect of spring forces. This layout was implemented by using
    the Jedi framework.
  ]],

  example = [[
    \tikz
      \graph[simple spring layout, node distance = 3cm, speed = 2, nodes={as=,circle, draw, inner sep=3pt,outer sep=0pt}, coarsen = true, maximum step = 1]{
        a -- {b, c, d, e},
        b -- {c, d, e},
        c -- {d, e},
        d --e
      };
  ]]
}




-- Implementation starts here:

function SimpleSpringClass:run()
  --Generate new force class
  simple_spring = ForceController.new(self.ugraph)

  --add all required forces
  simple_spring:addForce{
    force_type = ForceGraphDistance,
    fun_u      = function (data) return data.k*(data.k-data.d) end,
    n          = 1,
    epoch     = {"after expand", "during expand"}
  }

  -- run algorithm
  simple_spring:run()
end

return SimpleSpringClass