-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



---
-- @section subsection {Spanning Tree Computation}
--
-- \label{subsection-gd-spanning-tree}
-- Although the algorithms of this library are tailored to layout trees,
-- they will work for any graph as input. First, if the graph is not
-- connected, it is decomposed into connected components and these are
-- laid out individually. Second, for each component, a spanning tree of
-- the graph is computed first and the layout is computed for this
-- spanning tree; all other edges will still be drawn, but they have no
-- impact on the placement of the nodes. If the graph is already a tree,
-- the spanning tree will be the original graph.
--
-- The computation of the spanning tree is a non-trivial process since
-- a non-tree graph has many different possible spanning trees. You can
-- choose between different methods for deciding on a spanning tree, it
-- is even possible to implement new algorithms. (In the future, the
-- computation of spanning trees and the cycle removal in layered graph
-- drawing algorithms will be unified, but, currently, they are
-- implemented differently.)
--
-- Selects the (sub)algorithm that is to be used for computing spanning
-- trees whenever this is requested by a tree layout algorithm. The
-- default algorithm is |breadth first spanning tree|.
--%
--\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
--    \usegdlibrary{trees}}]
--\tikz \graph [tree layout, breadth first spanning tree]
--{
--  1 -- {2,3,4,5} -- 6;
--};
--\end{codeexample}
--%
--\begin{codeexample}[preamble={\usetikzlibrary{graphs,graphdrawing}
--    \usegdlibrary{trees}}]
--\tikz \graph [tree layout, depth first spanning tree]
--{
--  1 --[bend right] {2,3,4,5 [>bend left]} -- 6;
--};
--\end{codeexample}
--
-- @end

local SpanningTreeComputation = {}



-- Namespace
require("pgf.gd.trees").SpanningTreeComputation = SpanningTreeComputation


-- Imports
local lib     = require "pgf.gd.lib"

local Vertex   = require "pgf.gd.model.Vertex"
local Digraph  = require "pgf.gd.model.Digraph"


local declare  = require("pgf.gd.interface.InterfaceToAlgorithms").declare




-- ------------------------- --
-- General tree parameters   --
-- ------------------------- --




---
--
declare {
  key = "breadth first spanning tree",
  algorithm = {
    run =
      function (self)
        return SpanningTreeComputation.computeSpanningTree(self.ugraph, false, self.events)
      end
  },
  phase = "spanning tree computation",
  phase_default = true,

  summary = [["
    This key selects ``breadth first'' as the (sub)algorithm for
    computing spanning trees. Note that this key does not cause a graph
    drawing scope to start; the key only has an effect in conjunction
    with keys like |tree layout|.
"]],
  documentation = [["
    The algorithm will be called whenever a graph drawing algorithm
    needs a spanning tree on which to operate. It works as follows:
    %
    \begin{enumerate}
      \item It looks for a node for which the |root| parameter is
        set. If there are several such nodes, the first one is used.
        If there are no such nodes, the first node is used.

        Let call the node determined in this way the \emph{root node}.
      \item For every edge, a \emph{priority} is determined, which is a
        number between 1 and 10. How this happens, exactly, will be
        explained in a moment. Priority 1 means ``most important'' while
        priority 10 means ``least important''.
      \item Starting from the root node, we now perform a breadth first
        search through the tree, thereby implicitly building a spanning
        tree: Suppose for a moment that all edges have priority~1. Then,
        the algorithm works just the way that a normal breadth first
        search is performed: We keep a queue of to-be-visited nodes and
        while this queue is not empty, we remove its first node. If this
        node has not yet been visited, we add all its neighbors at the
        end of the queue. When a node is taken out of the queue, we make
        it the child of the node whose neighbor it was when it was
        added. Since the queue follows the ``first in, first out''
        principle (it is a fifo queue), the children of the root will be
        all nodes at distance $1$ form the root, their children will be
        all nodes at distance $2$, and so on.
      \item Now suppose that some edges have a priority different
        from~1, in which case things get more complicated. We now keep
        track of one fifo queue for each of the ten possible
        priorities. When we consider the neighbors of a node, we actually
        consider all its incident edges. Each of these edges has a certain
        priority and the neighbor is put into the queue of the edge's
        priority. Now, we still remove nodes normally from the queue for
        priority~1; only if this queue is empty and there is still a node
        in the queue for priority~2 we remove the first element from this
        queue (and proceed as before). If the second queue is also empty,
        we try the third, and so on up to the tenth queue. If all queues
        are empty, the algorithm stops.
    \end{enumerate}

    The effect of the ten queues is the following: If the edges of
    priority $1$ span the whole graph, a spanning tree consisting solely
    of these edges will be computed. However, if they do not, once we
    have visited reachable using only priority 1 edges, we will extend
    the spanning tree using a priority 2 edge; but then we once switch
    back to using only priority 1 edges. If neither priority~1 nor
    priority~2 edges suffice to cover the whole graph, priority~3 edges
    are used, and so on.
  "]]
}

---

declare {
  key = "depth first spanning tree",
  algorithm = {
    run =
      function (self)
        return SpanningTreeComputation.computeSpanningTree(self.ugraph, true, self.events)
      end
  },
  phase = "spanning tree computation",

  summary = [["
    Works exactly like |breadth first spanning tree| (same handling of
    priorities), only the queues are now lifo instead of
    fifo.
  "]]
}

---
--
declare {
  key     = "root",
  type    = "boolean",
  default = true,

  summary = [["
    This Boolean parameter is used in the computation of spanning
    trees. When can be set for a node, this node will be used as the
    root for the spanning tree computation. If several nodes have this
    option set, the first node will be used.
  "]]
}


---
--
declare {
  key = "span priority",
  type = "number",

  summary = [["
    Explicitly sets the ``span priority'' of an edge to \meta{number}, which must be
    a number between |1| and |10|. The priority of edges is used by
    spanning tree computations, see |breadth first spanning tree|.
  "]]
}



---
-- when it comes to choosing which edges are part of the spanning tree.
declare {
  key = "span edge",
  use = {
    { key = "span priority", value = 1 },
  },

  summary = [["
    An easy-to-remember shorthand for |span priority=1|. When this key
    is used with an edge, it will always be preferred over other edges
  "]]
}




---
--
declare {
  key = "no span edge",
  use = {
    { key = "span priority", value = 10 },
  },

  summary = [["
    An easy-to-remember shorthand for |span priority=10|. This causes
    the edge to be used only as a last resort as part of a spanning
    tree.
  "]],
  documentation = [["
    In the example, we add lots of edges that would normally be
    preferred in the computation of the spanning tree, but use
    |no span edge| to cause the algorithm to ignore these edges.
  "]],
  examples = [["
    \tikz \graph [tree layout, nodes={draw}, sibling distance=0pt,
                  every group/.style={
                    default edge kind=->, no span edge,
                    path=source}]
    {
      5 -> {
        "1,3" -> {0,2,4},
        11    -> {
          "7,9" -> { 6, 8, 10 }
        }
      }
    };
  "]]
}



---
declare {
  key = "span priority ->",
  type = "number",
  initial = "3",

  summary = [["
    This key stores the span priority of all edges whose direction is
    |->|. There are similar keys for all other directions, such as
    |span priority <-| and so on.
  "]],
  documentation = [["
    When you write
    %
\begin{codeexample}[code only]
graph { a -> b -- c <- [span priority=2] d }
\end{codeexample}
    %
    the priority of the edge from |a| to |b| would be the current
    value of the key |span priority ->|, the priority of the edge from
    |b| to |c| would be the current value of |span priority --|, and
    the priority of the edge from |c| to |d| would be |2|, regardless
    of the value of |span priority <-|.

    The defaults for the priorities are:
    %
    \begin{itemize}
      \item |span priority ->  = 3|
      \item |span priority --  = 5|
      \item |span priority <-> = 5|
      \item |span priority <-  = 8|
      \item |span priority -!- = 10|
    \end{itemize}
  "]]
}



---

declare {
  key = "span priority reversed ->",
  type = "number",
  initial = "9",

  documentation = [["
    This key stores the span priority of traveling across reversed
    edges whose actual direction is |->| (again, there are similar keys
    for all other directions).
  "]],
  documentation = [["
    When you write
    %
\begin{codeexample}[code only]
graph { a -> b -- c <- [span priority=2] d }
\end{codeexample}
    %
    there are, in addition to the priorities indicated above, also
    further edge priorities: The priority of the (reversed) edge |b|
    to |a| is |span priority reversed ->|, the priority of the
    (reversed) edge |c| to |b| is |span priority reversed --|, and the
    span priority of the reversed edge |d| to |c| is |2|, regardless
    of the value of |span priority reversed <-|.

    The defaults for the priorities are:
    %
    \begin{itemize}
      \item |span priority reversed ->  = 9|
      \item |span priority reversed --  = 5|
      \item |span priority reversed <-> = 5|
      \item |span priority reversed <-  = 7|
      \item |span priority reversed -!- = 10|
    \end{itemize}

    The default priorities are set in such a way, that non-reversed |->|
    edges have top priorities, |--| and |<->| edges have the same
    priorities in either direction, and |<-| edges have low priority in
    either direction (but going |a <- b| from |b| to |a| is given higher
    priority than going from |a| to |b| via this edge and also higher
    priority than going from |b| to |a| in |a -> b|).

    Keys like |span using directed| change the priorities ``en bloc''.
  "]]
}


declare {
  key = "span priority <-",
  type = "number",
  initial = "8",
}

declare {
  key = "span priority reversed <-",
  type = "number",
  initial = "7",
}

declare {
  key = "span priority --",
  type = "number",
  initial = "5",
}

declare {
  key = "span priority reversed --",
  type = "number",
  initial = "5",
}

declare {
  key = "span priority <->",
  type = "number",
  initial = "5",
}

declare {
  key = "span priority reversed <->",
  type = "number",
  initial = "5",
}

declare {
  key = "span priority -!-",
  type = "number",
  initial= "10",
}

declare {
  key = "span priority reversed -!-",
  type = "number",
  initial= "10",
}

---

declare {
  key = "span using directed",
  use = {
    { key = "span priority reversed <-", value = 3},
    { key = "span priority <->", value = 3},
    { key = "span priority reversed <->", value = 3},
  },
  summary = [["
    This style sets a priority of |3| for all edges that are directed
    and ``go along the arrow direction'', that is, we go from |a| to
    |b| with a priority of |3| for the cases |a -> b|, |b <- a|,
    |a <-> b|, and |b <-> a|.
    This strategy is nice with trees specified with both forward and
    backward edges.
  "]],
  examples = [["
    \tikz \graph [tree layout, nodes={draw}, sibling distance=0pt,
                  span using directed]
    {
      3 <- 5[root] -> 8,
      1 <- 3 -> 4,
      7 <- 8 -> 9,
      1 -- 4 -- 7 -- 9
    };
  "]]
}

---

declare {
  key = "span using all",
  use = {
    { key = "span priority <-", value = 5},
    { key = "span priority ->", value = 5},
    { key = "span priority <->", value = 5},
    { key = "span priority --", value = 5},
    { key = "span priority -!-", value = 5},
    { key = "span priority reversed <-", value = 5},
    { key = "span priority reversed ->", value = 5},
    { key = "span priority reversed <->", value = 5},
    { key = "span priority reversed --", value = 5},
    { key = "span priority reversed -!-", value = 5},
  },

  summary = [["
    Assings a uniform priority of 5 to all edges.
  "]]
}


-- The implementation

--
-- Compute a spanning tree of a graph
--
-- The algorithm will favor nodes according to their priority. This is
-- determined through an edge priority function.
--
-- @param ugraph An undirected graph for which the spanning tree
-- should be computed
-- @param dfs True if depth first should be used, false if breadth
-- first should be used.
--
-- @return A new graph that is a spanning tree.

function SpanningTreeComputation.computeSpanningTree (ugraph, dfs, events)

  local tree = Digraph.new (ugraph) -- copy vertices

  local edge_priorities = ugraph.options['/graph drawing/edge priorities']

  local root = lib.find(ugraph.vertices, function (v) return v.options['root'] end) or ugraph.vertices[1]

  -- Traverse tree, giving preference to directed edges and, that
  -- failing, to undirected and bidirected edges, and, that failing,
  -- all other edges.
  local marked = {}

  local stacks = { -- 10 stacks for 10 priorities, with 1 being the highest
    { { parent = nil, node = root}, top = 1, bottom = 1 },
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1},
    { top = 0, bottom = 1}
  }

  local function stack_is_non_empty (s) return s.top >= s.bottom end

  while lib.find(stacks, stack_is_non_empty) do
    local parent, node

    for _,stack in ipairs(stacks) do
      if stack_is_non_empty(stack) then
        -- Pop
        parent = stack[stack.top].parent
        node = stack[stack.top].node

        stack[stack.top] = nil
        stack.top = stack.top - 1

        break
      end
    end

    if not marked[node] then

      -- The node is good!
      marked[node] = true

      if parent then
        tree:connect(parent,node)
      end

      local arcs = ugraph:outgoing(node)

      for j=1,#arcs do
        local arc = arcs[dfs and j or #arcs - j + 1]
        local head = arc.head

        if not marked[head] then
          local priority = arc:spanPriority()
          local stack = assert(stacks[priority], "illegal edge priority")
          if dfs then
            stack.top = stack.top + 1
            stack[stack.top] = { parent = node, node = head}
          else
            stack.bottom = stack.bottom - 1
            stack[stack.bottom] = { parent = node, node = head}
          end
        end
      end
    end
  end

  -- Now, copy vertex list
  local copy = {}
  for i,v in ipairs(tree.vertices) do
    copy[i] = v
  end

  -- Now, setup child lists
  for _,v in ipairs(copy) do

    -- Children as they come from the spanning tree computation
    tree:sortOutgoing(v, function (a,b) return a:eventIndex() < b:eventIndex() end)
    local outgoings = tree:outgoing(v)

    -- Compute children as they come in the event list:
    local children = {}

    local i = (v.event.index or 0)+1
    while i <= #events and events[i].kind == "edge" do
      i = i + 1
    end

    if events[i] and events[i].kind == "begin" and events[i].parameters == "descendants" then
      -- Ok, the node is followed by a descendants group
      -- Now scan for nodes that are not inside a descendants group
      local stop = events[i].end_index
      local j = i+1
      while j <= stop do
        if events[j].kind == "node" then
          children[#children+1] = events[j].parameters
        elseif events[j].kind == "begin" and events[j].parameters == "descendants" then
          j = events[j].end_index
        end
        j = j + 1
      end

      -- Test, whether outgoings and children contain the same nodes:
      local function same_elements()
        local hash = {}
        for v,c in ipairs(outgoings) do
          hash[c.head] = true
        end
        local count = 0
        for _,c in pairs(children) do
          if c ~= "" then
            count = count + 1
            if not hash[c] or count > #outgoings then
              return false
            end
          end
        end
        return count == #outgoings
      end

      if same_elements() and #outgoings > 0 then
        -- increase number of children, if necessary
        local needed = math.max(#children, lib.lookup_option('minimum number of children', v, ugraph))
        for i=1,#children do
          if children[i] ~= "" then
            local d = children[i].options['desired child index']
            needed = d and math.max(needed, d) or needed
          end
        end

        local new_children = {}
        for i=1,#children do
          if children[i] ~= "" then
            local d = children[i].options['desired child index']
            if d then
              local target = d

              while new_children[target] do
                target = 1 + (target % #children)
              end
              new_children[target] = children[i]
            end
          end
        end
        for i=1,#children do
          if children[i] ~= "" then
            local d = children[i].options['desired child index']
            if not d then
              local target = i

              while new_children[target] do
                target = 1 + (target % #children)
              end
              new_children[target] = children[i]
            end
          end
        end
        for i=1,needed do
          if not new_children[i] then
            local new_child = Vertex.new{ kind = "dummy" }
            new_children[i] = new_child
            tree:add {new_child}
            tree:connect(v,new_child)
          end
        end

        tree:orderOutgoing(v,new_children)
      end
    end
  end

  tree.root = root

  return tree
end



-- Done

return SpanningTreeComputation
