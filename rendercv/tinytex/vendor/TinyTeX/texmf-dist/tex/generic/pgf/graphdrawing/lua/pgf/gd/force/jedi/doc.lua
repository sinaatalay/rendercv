-- Copyright 2014 by Ida Bruhns and Till Tantau
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- Imports
local key           = require 'pgf.gd.doc'.key
local documentation = require 'pgf.gd.doc'.documentation
local summary       = require 'pgf.gd.doc'.summary
local example       = require 'pgf.gd.doc'.example


--------------------------------------------------------------------
key          "maximum step"

summary
[[
This option determines the maximum distance every vertex is allowed to travel
in one iteration.
]]

documentation
[[
No matter how large the forces influencing a vertex, the effect
on the drawing should be limited to avoid vertices "jumping" from one side of
the canvas to each other due to a strong force pulling them further than their
ideal destination. The amount of space a vertex is allowed to travel in one
iteration is limited by the \lstinline{maximum step} parameter. It is $5000$
by default. That means by default, this parameter should not get in your way.
]]


example
[[
\tikz
  \graph[social degree layout, iterations = 2, maximum time = 2, maximum step = 6pt, coarsen = false]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 2, maximum time = 2, maximum step = 12pt, coarsen = false]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]
--------------------------------------------------------------------





--------------------------------------------------------------------
key          "speed"

summary
[[
This is a factor every calculated step is multiplied by.
]]

documentation
[[
The speed is the distance a vertex travels if it is influenced by a force of
$1$N$\cdot\gamma$. The speed is only a factor that will influence the total
amount every vertex can move: Half the speed makes half the movement, twice
the speed doubles the distance traveled.
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 1, maximum time = 1, maximum step = 100, speed = 0.2, coarsen = false]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 1, maximum time= 1, maximum step = 100, speed = 0.4, coarsen = false]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key          "maximum time"

summary
[[
The highest amount of virtual time the algorithm is allowed to take.
]]

documentation
[[
This option is part of the virtual time construct of Jedi. The virtual time
concept allows graph drawing algorithm engineers to switch forces on and of
after a relative or absolute amount of time has elapsed. If the iterations
stay the same, doubling the maximum time has the same effect as doubling the
speed: Vertices move faster, but it is possible they miss their intended
destination. Also increasing the iterations changes the "resolution" of the
graph drawing algorithm: More steps are simulated in the same time.
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 20, maximum time = 100, coarsen = false, maximum step = 0.5, gravity = 2]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 20, maximum time = 200, coarsen = false, maximum step = 0.5, gravity = 2]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key          "find equilibrium"

summary
[[
If this option is |true|, the framework checks the vertex movement to detect
low movement near the equilibrium and stop the algorithm.
]]

documentation
[[
Since we often do not know how many iterations are enough, the framework will
detect when the vertices (almost) stop moving and stop the algorithm. After
each iteration, the framework adds up the net force influencing all the
vertices. If it falls below the threshold |epsilon|, the algorithm
will ignore the left over iterations and terminate. You can disable this
behavior by setting this parameter to |false|. Allowing the framework to find
the equilibrium usually saves you time, while allowing more iterations (or a
lower threshold) generates higher quality drawings.
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 300, maximum time = 300, coarsen = false,  maximum step = 10, epsilon = 10]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 300, maximum time = 300,  maximum step = 10, find equilibrium = false]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key          "epsilon"

summary
[[
The threshold for the |find equilibrium| option.
]]

documentation
[[
This key specifies the threshold for the |find equilibrium| option. The lower
epsilon, the longer the graph drawing algorithm will take, but the closer the
resulting drawing will be to the true energy minimum.
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 200, maximum time = 200, maximum step = 10, coarsen = false, epsilon = 2]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 200, maximum time = 200, maximum step = 10, epsilon = 12, coarsen = false]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key          "snap to grid"

summary
[[
This option enables the post-processing step |snap to grid|.
]]

documentation
[[
This key is the on/off-switch for the grid forces. The |snap to grid| option
triggers a form of post-processing were all vertices are pulled to the closest
point on a virtual grid. Please note that there is no repulsive force between
the vertices, so it is possible that two vertices are pulled to the same grid
point. The grid size is determined by the parameters |grid x length| and
|grid y length|.
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 100, maximum time = 100, maximum step = 10]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]

example
[[
\tikz{
  \graph[social degree layout, iterations = 100, maximum time = 100, snap to grid =true, grid x length = 5mm, grid y length = 5mm, maximum step = 10]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key          "grid x length"

summary
[[
This option determines the cell size in $x$ direction for the |snap to grid|
option.
]]

documentation
[[
The size of the cells of the virtual grid can be configured by the user. This
key allows a configuration of the horizontal cell width.
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 100, maximum time = 100, snap to grid =true, grid x length = 5mm, grid y length = 5mm, maximum step = 10]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 100, maximum time = 100, snap to grid =true, grid x length = 9mm, grid y length = 5mm, maximum step = 10]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]
--------------------------------------------------------------------



--------------------------------------------------------------------
key          "grid y length"

summary
[[
This option determines the cell size in $x$ direction for the |snap to grid|
option.
]]

documentation
[[
Same as |grid x length|, but in vertical direction (height of the cells).
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 100, maximum time = 100, snap to grid =true, grid x length = 5mm, grid y length = 5mm, maximum step = 10]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]

example
[[
\tikz
  \graph[social degree layout, iterations = 100, maximum time = 100, snap to grid =true, grid x length = 5mm, grid y length = 9mm, maximum step = 10]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]
--------------------------------------------------------------------


--------------------------------------------------------------------
key "mass"

summary
[[
  The mass of a vertex determines how fast it can move. Vertices
  with higher mass move slower.
]]

documentation
[[
  The mass of a vertex determines how fast this vertex
  moves. Mass is directly inverse proportional to the distance the vertex
  moves. In contrast to the global speed factor, mass usually only affects a
  single vertex. A vertex with a higher mass will move slower if affected by
  the same mass than a vertex with a lower mass. By default, each vertex has a
  mass of $1$.
]]

example
[[
  \tikz
  \graph[social degree layout, iterations = 100, maximum time = 100, maximum displacement per step = 10]{
    a1 -- {a2, a3, a4, a5},
    b1 -- {b2 -- {b3, b4}, b5}
  };
]]

example
[[
  \tikz
  \graph[social degree layout, iterations = 100, maximum time = 100, maximum displacement per step = 10]{
    a1 -- {a2, a3, a4, a5},
    b1[mass = 4] -- {b2 -- {b3, b4}, b5}
  };
]]
--------------------------------------------------------------------


--------------------------------------------------------------------
key "coarsening weight"

summary
[[
  The coarsening weight of a vertex determines when it will be
  coarsened.
]]

documentation
[[
  Vertices with higher coarsening weight are considered more important and
  will be coarsened later, or not at all.
]]
--------------------------------------------------------------------
