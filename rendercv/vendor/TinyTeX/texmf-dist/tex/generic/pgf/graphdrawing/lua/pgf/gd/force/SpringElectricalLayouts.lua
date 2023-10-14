-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Imports
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare


---
-- @section subsection {Spring Electrical Layouts}
--
-- @end



---

declare {
  key = "spring electrical layout",
  use = {
    { key = "spring electrical Hu 2006 layout" },
    { key = "spring constant", value = "0.2" }
  },

  summary = [["
    This key selects Hu's 2006 spring electrical layout with
    appropriate settings for some parameters.
  "]]
}


---

declare {
  key = "spring electrical layout'",
  use = {
    { key = "spring electrical Walshaw 2000 layout" },
    { key = "spring constant", value = "0.01" },
    { key = "convergence tolerance", value = "0.001" },
  },

  summary = [["
    This key selects Walshaw's 2000 spring electrical layout with
    appropriate settings for some parameters.
  "]]
}
