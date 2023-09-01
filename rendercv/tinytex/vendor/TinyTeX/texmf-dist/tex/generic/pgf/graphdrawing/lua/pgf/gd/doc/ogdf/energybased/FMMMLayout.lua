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
key           "FMMMLayout"
summary       "The fast multipole multilevel layout algorithm."

documentation
[[
|FMMMLayout| implements a force-directed graph drawing
method suited also for very large graphs. It is based on a
combination of an efficient multilevel scheme and a strategy for
approximating the repulsive forces in the system by rapidly
evaluating potential fields.

The implementation is based on the following publication:
%
\begin{itemize}
  \item Stefan Hachul, Michael J\"unger: Drawing Large Graphs with
    a Potential-Field-Based Multilevel Algorithm. \emph{12th
      International Symposium on Graph Drawing 1998 (GD '04)},
      New York, LNCS 3383, pp. 285--295, 2004.
\end{itemize}
]]

example
[[
\tikz \graph [FMMMLayout] { a -- {b,c,d} -- e -- a };
]]


example
[[
\tikz [nodes={text height=.7em, text depth=.2em,
              draw=black!20, thick, fill=white, font=\footnotesize},
       >={Stealth[round,sep]}, rounded corners, semithick]
  \graph [FMMMLayout, node sep=1mm, variation=2] {
    "5th Edition" -> { "6th Edition", "PWB 1.0" };
    "6th Edition" -> { "LSX",  "1 BSD", "Mini Unix", "Wollongong", "Interdata" };
    "Interdata" ->[orient=down] "Unix/TS 3.0",
    "Interdata" -> { "PWB 2.0", "7th Edition" };
    "7th Edition" -> { "8th Edition", "32V", "V7M", "Ultrix-11", "Xenix", "UniPlus+" };
    "V7M" -> "Ultrix-11";
    "8th Edition" -> "9th Edition";
    "1 BSD" -> "2 BSD" -> "2.8 BSD" -> { "Ultrix-11", "2.9 BSD" };
    "32V" -> "3 BSD" -> "4 BSD" -> "4.1 BSD" -> { "4.2 BSD", "2.8 BSD", "8th Edition" };
    "4.2 BSD" -> { "4.3 BSD", "Ultrix-32" };
    "PWB 1.0" -> { "PWB 1.2" -> "PWB 2.0", "USG 1.0" -> { "CB Unix 1", "USG 2.0" }};
    "CB Unix 1" -> "CB Unix 2" -> "CB Unix 3" -> { "Unix/TS++", "PDP-11 Sys V" };
    { "USG 2.0" -> "USG 3.0", "PWB 2.0", "Unix/TS 1.0" } -> "Unix/TS 3.0";
    { "Unix/TS++", "CB Unix 3", "Unix/TS 3.0" } ->
      "TS 4.0" -> "System V.0" -> "System V.2" -> "System V.3";
  };
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "FMMMLayout.randSeed"
summary       "Sets the random seed for the |FMMMLayout|."
documentation
[[
By changing this number, you can vary the appearance of the generated
graph drawing. This key is an alias for |random seed|, which in turn
can be set by using the |variation| key.
]]

example
[[
\tikz \graph [FMMMLayout, variation=1] { a -- {b,c,d} -- e -- a };
]]
example
[[
\tikz \graph [FMMMLayout, variation=2] { a -- {b,c,d} -- e -- a };
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "FMMMLayout.unitEdgeLength"
summary       "The ``ideal'' padding between two nodes."

documentation
[[
The algorithm will try to make the padding between any two vertices
this distance. Naturally, this is not always possible, so, normally,
distance will actually be different. This key is an alias for the more
natural |node sep|.
]]

example
[[
\tikz {
  \graph [FMMMLayout, node sep=1cm] { subgraph C_n[n=6]; };

  \draw [red, ultra thick, |-|] (1.south) -- ++(down:1cm);
}
]]
example
[[
\tikz {
  \graph [FMMMLayout, node sep=5mm] { subgraph C_n[n=6]; };

  \draw [red, ultra thick, |-|] (1.south) -- ++(down:5mm);
}
]]
--------------------------------------------------------------------------------


-- Local Variables:
-- mode:latex
-- End:
