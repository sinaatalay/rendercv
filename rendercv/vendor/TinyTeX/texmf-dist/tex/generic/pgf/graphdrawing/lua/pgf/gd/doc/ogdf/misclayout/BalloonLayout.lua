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
key           "BalloonLayout"
summary       "A ``balloon layout''."

documentation
[[
This algorithm computes a radial (balloon) layout based on a
spanning tree. The algorithm is partially based on the paper
\emph{On Balloon Drawings of Rooted Trees} by Lin and Yen and on
\emph{Interacting with Huge Hierarchies: Beyond Cone Trees} by
Carriere and Kazman.
]]

example
[[
\tikz \graph [BalloonLayout] { a -- {b,c,d -- {e,f,h,h,i}, j -- k -- {l,m,n}} };
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "BalloonLayout.evenAngles"
summary       "Subtrees may be assigned even angles or angles depending on their size."
--------------------------------------------------------------------------------


-- Local Variables:
-- mode:latex
-- End: