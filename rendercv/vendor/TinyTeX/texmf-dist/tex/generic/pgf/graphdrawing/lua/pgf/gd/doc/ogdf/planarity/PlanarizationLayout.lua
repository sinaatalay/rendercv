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
key           "PlanarizationLayout"
summary       "The planarization layout algorithm."

documentation
[[
  A |PlanarizationLayout| represents a customizable implementation
  of the planarization approach for drawing graphs. The implementation
  used in PlanarizationLayout is based on the following  publication:
  %
  \begin{itemize}
    \item C. Gutwenger, P. Mutzel: \emph{An Experimental Study of Crossing
       Minimization Heuristics.} 11th International Symposium on Graph
       Drawing 2003, Perugia (GD '03), LNCS 2912, pp. 13--24, 2004.
  \end{itemize}
]]

example
[[
\tikz \graph [PlanarizationLayout] { a -- {b,c,d,e,f} -- g -- a };
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "PlanarizationLayout.preprocessCliques"
summary       "Configures, whether cliques are collapsed in a preprocessing step."
documentation
[[
  If set to true, a preprocessing for cliques (complete subgraphs)
  is performed and cliques will be laid out in a special form (straight-line,
  not orthogonal). The preprocessing may reduce running time and improve
  layout quality if the input graphs contains dense subgraphs.
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "PlanarizationLayout.minCliqueSize"
summary       "The minimum size of cliques collapsed in preprocessing."
--------------------------------------------------------------------------------


-- Local Variables:
-- mode:latex
-- End: