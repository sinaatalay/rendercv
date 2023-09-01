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
key           "FastMultipoleEmbedder"
summary       "Implementation of a fast multipole embedder by Martin Gronemann."
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "FastMultipoleEmbedder.numIterations"
summary       "sets the maximum number of iterations"
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "FastMultipoleEmbedder.multipolePrec"
summary       "sets the number of coefficients for the expansions. default = 4"
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "FastMultipoleEmbedder.defaultEdgeLength"
summary       ""
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "FastMultipoleEmbedder.defaultNodeSize"
summary       ""
--------------------------------------------------------------------------------


-- Local Variables:
-- mode:latex
-- End:
