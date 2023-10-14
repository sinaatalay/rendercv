-- Copyright 2012 by Till Tantau
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


--------------------------------------------------------------------
key          "desired at"

summary
[[
When you add this key to a node in a graph, you ``desire''
that the node should be placed at the \meta{coordinate} by the graph
drawing algorithm.
]]

documentation
[[
Now, when you set this key for a single node of a graph,
then, by shifting the graph around, this ``wish'' can obviously
always be fulfill:
%
\begin{codeexample}[preamble={    \usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{force}}]
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (3,2);
  \graph [spring layout]
  {
    a [desired at={(1,2)}] -- b -- c -- a;
  };
\end{tikzpicture}
\end{codeexample}
%
\begin{codeexample}[preamble={    \usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{force}}]
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (3,2);
  \graph [spring layout]
  {
    a -- b[desired at={(2,1)}] -- c -- a;
  };
\end{tikzpicture}
\end{codeexample}
%
Since the key's name is a bit long and since the many braces and
parentheses are a bit cumbersome, there is a special support for
this key inside a |graph|: The standard |/tikz/at| key is redefined
inside a |graph| so that it points to |/graph drawing/desired at|
instead. (Which is more logical anyway, since it makes no sense to
specify an |at| position for a node whose position it to be computed
by a graph drawing algorithm.) A nice side effect of this is that
you can use the |x| and |y| keys (see
Section~\ref{section-graphs-xy}) to specify desired positions:
%
\begin{codeexample}[preamble={    \usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{force}}]
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (3,2);
  \graph [spring layout]
  {
    a -- b[x=2,y=0] -- c -- a;
  };
\end{tikzpicture}
\end{codeexample}
%
\begin{codeexample}[preamble={    \usetikzlibrary{graphs,graphdrawing}
    \usegdlibrary{layered}}]
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (3,2);
  \graph [layered layout]
  {
    a [x=1,y=2] -- { b, c } -- {e, f} -- a
  };
\end{tikzpicture}
\end{codeexample}

A problem arises when two or more nodes have this key set, because
then your ``desires'' for placement and the positions computed by
the graph drawing algorithm may clash. Graph drawing algorithms are
``told'' about the desired positions. Most algorithms will simply
ignore these desired positions since they will be taken care of in
the so-called post-anchoring phase, see below. However, for some
algorithms it makes a lot of sense to fix the positions of some
nodes and only compute the positions of the other nodes relative
to these nodes. For instance, for a |spring layout| it makes perfect
sense that some nodes are ``nailed to the canvas'' while other
nodes can ``move freely''.
]]

--[[
% TODOsp: codeexamples: the following 3 examples need these libraries
%    \usetikzlibrary{graphs,graphdrawing}
%    \usegdlibrary{force}
--]]
example
[[
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (3,2);
  \graph [spring layout]
  {
    a[x=1] -- { b, c, d, e -- {f,g,h} };
    { h, g } -- a;
  };
\end{tikzpicture}
]]

example
[[
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (3,2);
  \graph [spring layout]
  {
    a -- { b, c, d[x=0], e -- {f[x=2], g, h[x=1]} };
    { h, g } -- a;
  };
\end{tikzpicture}
]]

example
[[
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (3,2);
  \graph [spring layout]
  {
    a -- { b, c, d[x=0], e -- {f[x=2,y=1], g, h[x=1]} };
    { h, g } -- a;
  };
\end{tikzpicture}
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key          "anchor node"

summary
[[
This option can be used with a graph to specify a node that
should be used for anchoring the whole graph.
]]

documentation
[[
When this option is specified, after the layout has been computed, the
whole graph will be shifted in such a way that the \meta{node name} is
either
%
\begin{itemize}
  \item at the current value of |anchor at| or
  \item at the position that is specified in the form of a
    |desired at| for the \meta{node name}.
\end{itemize}
%
Note how in the last example |c| is placed at |(1,1)| rather than
|b| as would happen by default.
]]

--[[
% TODOsp: codeexamples: the following 4 examples need these libraries
%    \usetikzlibrary{graphs,graphdrawing}
%    \usegdlibrary{layered}
--]]
example
[[
\tikz \draw (0,0)
  -- (1,0.5) graph [edges=red,  layered layout, anchor node=a] { a -> {b,c} }
  -- (1.5,0) graph [edges=blue, layered layout,
                    anchor node=y, anchor at={(2,0)}]          { x -> {y,z} };
]]

example
[[
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (3,2);

  \graph [layered layout, anchor node=c, edges=rounded corners]
    { a -- {b [x=1,y=1], c [x=1,y=1] } -- d -- a};
\end{tikzpicture}
]]
--------------------------------------------------------------------




--------------------------------------------------------------------
key          "anchor at"

summary
[[
The coordinate at which the graph should be anchored when no
explicit anchor is given for any node. The initial value is the origin.
]]

example
[[
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (2,2);

  \graph [layered layout, edges=rounded corners, anchor at={(1,2)}]
    { a -- {b, c [anchor here] } -- d -- a};
\end{tikzpicture}
]]
--------------------------------------------------------------------




--------------------------------------------------------------------
key          "anchor here"

summary
[[
This option can be passed to a single node (rather than the
graph as a whole) in order to specify that this node should be used
for the anchoring process.
]]

documentation
[[
In the example, |c| is placed at the origin since this is the
default |anchor at| position.
]]

example
[[
\begin{tikzpicture}
  \draw [help lines] (0,0) grid (2,2);

  \graph [layered layout, edges=rounded corners]
    { a -- {b, c [anchor here] } -- d -- a};
\end{tikzpicture}
]]
--------------------------------------------------------------------
