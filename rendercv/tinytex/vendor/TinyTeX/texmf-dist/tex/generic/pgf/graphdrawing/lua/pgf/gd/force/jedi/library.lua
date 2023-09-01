-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--- The library providing the graph drawing framework Jedi
-- This library requires all graph drawing algorithms and initial
-- positioning algorithms provided with the first release of Jedi.
-- It also defines the mass key attached to all vertices.

-- Library name
local jedi

-- require initial positioning algorithms
require "pgf.gd.force.jedi.initialpositioning.CircularInitialPositioning"
require "pgf.gd.force.jedi.initialpositioning.RandomInitialPositioning"
require "pgf.gd.force.jedi.initialpositioning.GridInitialPositioning"

-- require graph drawing algorithms
require "pgf.gd.force.jedi.algorithms.FruchtermanReingold"
require "pgf.gd.force.jedi.algorithms.HuSpringElectricalFW"
require "pgf.gd.force.jedi.algorithms.SimpleSpring"
require "pgf.gd.force.jedi.algorithms.SocialGravityCloseness"
require "pgf.gd.force.jedi.algorithms.SocialGravityDegree"


-- define parameter
local declare        = require "pgf.gd.interface.InterfaceToAlgorithms".declare

---
declare {
  key = "maximum displacement per step",
  type = "length",
  initial = "100",
  documentation_in = "pgf.gd.force.jedi.doc"
}

---
declare {
  key = "global speed factor",
  type = "length",
  initial = "1",
  documentation_in = "pgf.gd.force.jedi.doc"
}

---
declare {
  key = "maximum time",
  type = "number",
  initial = "50",
  documentation_in = "pgf.gd.force.jedi.doc"
}

---
declare {
  key = "find equilibrium",
  type = "boolean",
  initial = true,
  documentation_in = "pgf.gd.force.jedi.doc"
}

---
declare {
  key = "equilibrium threshold",
  type = "number",
  initial = "3",
  documentation_in = "pgf.gd.force.jedi.doc"
}

---
declare {
  key = "grid x length",
  type = "length",
  initial = "10pt",
  documentation_in = "pgf.gd.force.jedi.doc"
}

---
declare {
  key = "grid y length",
  type = "length",
  initial = "10pt",
  documentation_in = "pgf.gd.force.jedi.doc"
}

---
declare {
  key = "snap to grid",
  type = "boolean",
  initial = false,
  documentation_in = "pgf.gd.force.jedi.doc"
}

---
declare {
  key = "mass",
  type = "number",
  initial = "1",

  documentation_in = "pgf.gd.force.jedi.doc"
}

---
declare {
  key = "coarsening weight",
  type = "number",
  initial = "1",

  documentation_in = "pgf.gd.force.jedi.doc"
}
