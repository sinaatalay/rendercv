-- Copyright 2013 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local key           = require 'pgf.gd.doc'.key
local documentation = require 'pgf.gd.doc'.documentation
local summary       = require 'pgf.gd.doc'.summary
local example       = require 'pgf.gd.doc'.example


--------------------------------------------------------------------------------
key           "GEMLayout"
summary       "The energy-based GEM layout algorithm."

documentation [[
  The implementation used in |GEMLayout| is based on the following publication:
  %
  \begin{itemize}
    \item Arne Frick, Andreas Ludwig, Heiko Mehldau: \emph{A Fast Adaptive Layout
       Algorithm for Undirected Graphs.} Proc. Graph Drawing 1994,
       LNCS 894, pp. 388-403, 1995.
  \end{itemize}
]]
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.numberOfRounds"
summary       "Sets the maximal number of round per node."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.minimalTemperature"
summary       "Sets the minimal temperature."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.initialTemperature"
summary       "Sets the initial temperature; must be $\\ge$ |minimalTemperature|."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.gravitationalConstant"
summary       "Sets the gravitational constant; must be $\\ge 0$."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.desiredLength"
summary       "Sets the desired edge length; must be $\\ge 0$."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.maximalDisturbance"
summary       "Sets the maximal disturbance; must be $\\ge 0$."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.rotationAngle"
summary       "Sets the opening angle for rotations ($0 \\le x \\le \\pi / 2$)."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.oscillationAngle"
summary       "Sets the opening angle for oscillations ($0 \\le x \\le \\pi / 2$)."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.rotationSensitivity"
summary       "Sets the rotation sensitivity ($0 \\le x \\le 1$)."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.oscillationSensitivity"
summary       "Sets the oscillation sensitivity ($0 \\le x \\le 1$)."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "GEMLayout.attractionFormula"
summary       "sets the formula for attraction (1 = Fruchterman / Reingold, 2 = GEM)."
--------------------------------------------------------------------------------


-- Local Variables:
-- mode:latex
-- End:
