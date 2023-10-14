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
key           "SpringEmbedderFR"
summary       "The spring-embedder layout algorithm by Fruchterman and Reingold."

documentation [[
  The implementation used in SpringEmbedderFR is based on the following
  publication:

  Thomas M. J. Fruchterman, Edward M. Reingold: \emph{Graph Drawing by Force-directed
  Placement}. Software - Practice and Experience 21(11), pp. 1129--1164, 1991.
]]
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "SpringEmbedderFR.iterations"
summary       "Sets the number of iterations."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "SpringEmbedderFR.noise"
summary       "Sets the parameter noise."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "SpringEmbedderFR.scaleFunctionFactor"
summary       "Sets the scale function factor."
--------------------------------------------------------------------------------


-- Local Variables:
-- mode:latex
-- End:
