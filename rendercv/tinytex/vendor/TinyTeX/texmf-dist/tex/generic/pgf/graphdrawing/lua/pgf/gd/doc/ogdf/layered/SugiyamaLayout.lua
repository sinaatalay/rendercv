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
key           "SugiyamaLayout"
summary       "The OGDF implementation of the Sugiyama algorithm."

documentation [[
  This layout represents a customizable implementation of Sugiyama's
  layout algorithm. The implementation used in |SugiyamaLayout| is based
  on the following publications:

  \begin{itemize}
    \item Emden R. Gansner, Eleftherios Koutsofios, Stephen
      C. North, Kiem-Phong Vo: A technique for drawing directed
      graphs. \emph{IEEE Trans. Software Eng.} 19(3):214--230, 1993.
    \item Georg Sander: \emph{Layout of compound directed graphs.}
      Technical Report, Universität des Saarlandes, 1996.
  \end{itemize}
]]

example
[[
\tikz \graph [SugiyamaLayout] { a -- {b,c,d} -- e -- a };
]]

example
[[
\tikz \graph [SugiyamaLayout, grow=right] {
  a -- {b,c,d} -- e -- a
};
]]

example
[[
\tikz [nodes={text height=.7em, text depth=.2em,
              draw=black!20, thick, fill=white, font=\footnotesize},
       >={Stealth[round,sep]}, rounded corners, semithick]
  \graph [SugiyamaLayout, FastSimpleHierarchyLayout, grow=-80,
       level distance=1.5cm, sibling distance=7mm] {
    "5th Edition" -> { "6th Edition", "PWB 1.0" };
    "6th Edition" -> { "LSX",  "1 BSD", "Mini Unix", "Wollongong", "Interdata" };
    "Interdata" -> { "Unix/TS 3.0", "PWB 2.0", "7th Edition" };
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
key           "SugiyamaLayout.runs"
summary       "Determines, how many times the crossing minimization is repeated."
documentation
[[
Each repetition (except for the first) starts with
randomly permuted nodes on each layer. Deterministic behavior can
be achieved by setting |SugiyamaLayout.runs| to 1.
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "SugiyamaLayout.transpose"
documentation [[
  Determines whether the transpose step is performed
  after each 2-layer crossing minimization; this step tries to
  reduce the number of crossings by switching neighbored nodes on
  a layer.
]]
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
key           "SugiyamaLayout.fails"
documentation [[
  The number of times that the number of crossings may
  not decrease after a complete top-down bottom-up traversal,
  before a run is terminated.
]]
--------------------------------------------------------------------------------


-- Local Variables:
-- mode:latex
-- End:
