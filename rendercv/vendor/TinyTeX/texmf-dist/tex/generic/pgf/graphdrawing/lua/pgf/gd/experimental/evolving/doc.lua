-- Copyright 2012 by Malte Skambath
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

--


local key           = require 'pgf.gd.doc'.key
local documentation = require 'pgf.gd.doc'.documentation
local summary       = require 'pgf.gd.doc'.summary
local example       = require 'pgf.gd.doc'.example


--------------------------------------------------------------------
key          "animated tree layout"

summary      "This layout uses the Reingold--Tilform method for drawing trees."

documentation
[[
A method to create layouts for evolving graphs as an SVG animation.The Reingold--Tilford method is a standard method for drawing
trees. It is described in:

The algorithm, which is based on the Reingold--Tilford algorithm and
its implementation in |graphdrawing.trees|, is introduced in my Masthesis:
%
\begin{itemize}
  \item
    M.\ Skambath,
    \newblock Algorithmic Drawing of Evolving Trees, Masterthesis, 2016
\end{itemize}

You can use the same known graph macros as for other graph drawing
algorithms in Ti\emph{k}Z. In addition all keys and features that
are available for the static tree algorithm can be used:
%
\begin{codeexample}[animation list={1,1.5,2,2.5,3,3.5,4}]
  \tikz \graph[animated binary tree layout,
          nodes={draw,circle}, auto supernode,
        ] {
            {[when=1] 15 -> {10 -> { ,11}, 20       }},
            {[when=2] 15 -> {10 -> {3,11}, 20       }},
            {[when=3] 15 -> {10 -> {3,  }, 20       }},
            {[when=4] 15 -> {10 -> {3,  }, 20 -> 18 }},
        };
\end{codeexample}
]]


example
[[
\tikz[animated binary tree layout]
  \graph[nodes={draw,circle}, auto supernode] {
          {[when=1] 15 -> {10 -> { ,11}, 20       }},
          {[when=2] 15 -> {10 -> {3,11}, 20       }},
          {[when=3] 15 -> {10 -> {3,  }, 20       }},
          {[when=4] 15 -> {10 -> {3,  }, 20 -> 18 }},
        };
]]
--------------------------------------------------------------------



--------------------------------------------------------------------

--------------------------------------------------------------------



--------------------------------------------------------------------
key          "animated binary tree layout"

summary
[[ A layout based on the Reingold--Tilford method for drawing
binary trees.
]]

documentation
[[
This key executes:
%
\begin{enumerate}
  \item |animated tree layout|, thereby selecting the Reingold--Tilford method,
  \item |minimum number of children=2|, thereby ensuring the all nodes
    have (at least) two children or none at all, and
\end{enumerate}
]]


example
[[
]]

example
[[
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key          "extended animated binary tree layout"

summary
[[ This algorithm is similar to |animated binary tree layout|, only the
option \texttt{missing nodes get space} is executed and the
\texttt{significant sep} is zero.
]]

example
[[
]]
--------------------------------------------------------------------


