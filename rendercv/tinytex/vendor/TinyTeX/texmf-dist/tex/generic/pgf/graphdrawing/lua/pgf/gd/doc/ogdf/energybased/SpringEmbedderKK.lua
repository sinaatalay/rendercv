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
key           "SpringEmbedderKK"
summary       "The spring embedder of Kamada and Kawai"

documentation [[
  The implementation used in |SpringEmbedderKK| is based on
  the following publication:

  Tomihisa Kamada, Satoru Kawai: \emph{An Algorithm for Drawing
  General Undirected Graphs.} Information Processing Letters 31, pp. 7--15, 1989.

  There are some parameters that can be tuned to optimize the
  algorithm's behavior regarding runtime and layout quality.
  First of all note that the algorithm uses all pairs shortest path
  to compute the graph theoretic distance. This can be done either
  with BFS (ignoring node sizes) in quadratic time or by using
  e.g. Floyd's algorithm in cubic time with given edge lengths
  that may reflect the node sizes. Also |m_computeMaxIt| decides
  if the computation is stopped after a fixed maximum number of
  iterations. The desirable edge length can either be set or computed
  from the graph and the given layout.
]]
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "SpringEmbedderKK.stopTolerance"
summary       "Sets the value for the stop tolerance."
documentation [[
  Below this value, the system is regarded stable (balanced) and the
  optimization stopped.
]]
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "SpringEmbedderKK.desLength"
summary       "Sets desirable edge length directly"
--------------------------------------------------------------------------------


-- Local Variables:
-- mode:latex
-- End:
