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
key           "CircularLayout"
summary       "The circular layout algorithm."

documentation
[[
The implementation used in CircularLayout is based on the following publication:
%
\begin{itemize}
  \item Ugur Dogrus\"oz, Brendan Madden, Patrick Madden: Circular
    Layout in the Graph Layout Toolkit. \emph{Proc. Graph Drawing 1996,}
    LNCS 1190, pp. 92--100, 1997.
\end{itemize}
]]

example
[[
\tikz \graph [CircularLayout] {
  a -- b -- c -- a -- d -- e -- f -- g -- d;
  b -- {x,y,z};
};
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "CircularLayout.minDistCircle"
summary       "The minimal padding between nodes on a circle."

documentation "This is an alias for |part sep|."

example
[[
\tikz \graph [CircularLayout, part sep=1cm] {
  a -- b -- c -- a -- d -- e -- f -- g -- d;
  b -- {x,y,z};
};
]]
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "CircularLayout.minDistLevel"
summary       "The minimal padding between nodes on different levels."

documentation "This is an alias for |layer sep| and |level sep|."

example
[[
\tikz \graph [CircularLayout, layer sep=1cm] {
  a -- b -- c -- a -- d -- e -- f -- g -- d;
  b -- {x,y,z};
};
]]
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
key           "CircularLayout.minDistSibling"
summary       "The minimal padding between sibling nodes."

documentation "This is an alias for |sibling sep|."

example
[[
\tikz \graph [CircularLayout, sibling sep=1cm] {
  a -- b -- c -- a -- d -- e -- f -- g -- d;
  b -- {x,y,z};
};
]]
--------------------------------------------------------------------------------


-- Local Variables:
-- mode:latex
-- End: