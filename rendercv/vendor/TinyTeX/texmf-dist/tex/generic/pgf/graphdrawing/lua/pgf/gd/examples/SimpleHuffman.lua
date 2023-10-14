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
-- @section subsubsection {How To Generate Nodes Inside an Algorithm}
--
-- @end



-- Imports
local layered               = require "pgf.gd.layered"
local InterfaceToAlgorithms = require "pgf.gd.interface.InterfaceToAlgorithms"
local declare               = require "pgf.gd.interface.InterfaceToAlgorithms".declare

-- The class
local SimpleHuffman = {}


---

declare {
  key       = "simple Huffman layout",
  algorithm = SimpleHuffman,

  postconditions = {
    upward_oriented = true
  },

  summary = [["
    This algorithm demonstrates how an algorithm can generate new nodes.
  "]],
  documentation = [["
    The input graph should just consist of some nodes (without
    edges) and each node should have a |probability| key set. The nodes
    will then be arranged in a line (as siblings) and a Huffman tree
    will be constructed ``above'' these nodes. For the construction of
    the Huffman tree, new nodes are created and connected.

    \pgfgdset{
      HuffmanLabel/.style={/tikz/edge node={node[fill=white,font=\footnotesize,inner sep=1pt]{#1}}},
      HuffmanNode/.style={/tikz/.cd,circle,inner sep=0pt,outer sep=0pt,draw,minimum size=3pt}
    }

\begin{codeexample}[preamble={    \usetikzlibrary{graphs,graphdrawing,quotes}
    \usegdlibrary{examples}}]
\tikz \graph [simple Huffman layout,
              level distance=7mm, sibling distance=8mm, grow'=up]
{
  a ["0.5",  probability=0.5],
  b ["0.12", probability=0.12],
  c ["0.2",  probability=0.2],
  d ["0.1",  probability=0.1],
  e ["0.11", probability=0.11]
};
\end{codeexample}
    %
    The file starts with some setups and declarations:
    %
\begin{codeexample}[code only, tikz syntax=false]
-- File pgf.gd.examples.SimpleHuffman

local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare

-- The class
local SimpleHuffman = {}

declare {
  key            = "simple Huffman layout",
  algorithm      = SimpleHuffman,
  postconditions = { upward_oriented = true  }
  summary = "..."
}

declare {
  key = "probability",
  type = "number",
  initial = "1",
  summary = "..."
}

-- Import
local layered = require "pgf.gd.layered"
local InterfaceToAlgorithms = require "pgf.gd.interface.InterfaceToAlgorithms"
local Storage = require "pgf.gd.lib.Storage"

local probability = Storage.new()
local layer       = Storage.new()

function SimpleHuffman:run()
  -- Construct a Huffman tree on top of the vertices...
\end{codeexample}

    Next comes a setup, where we create the working list of vertices
    that changes as the Huffman coding method proceeds:
    %
\begin{codeexample}[code only, tikz syntax=false]
  -- Shorthand
  local function prop (v)
    return probability[v] or v.options['probability']
  end

  -- Copy the vertex table, since we are going to modify it:
  local vertices = {}
  for i,v in ipairs(self.ugraph.vertices) do
    vertices[i] = v
  end
\end{codeexample}

    The initial vertices are arranged in a line on the last layer. The
    function |ideal_sibling_distance| takes care of the rather
    complicated handling of the (possibly rotated) bounding boxes and
    separations. The |props| and |layer| are tables used by
    algorithms to ``store stuff'' at a vertex or at an arc. The
    table will be accessed by |arrange_layers_by_baselines| to
    determine the ideal vertical placements.
    %
\begin{codeexample}[code only, tikz syntax=false]
  -- Now, arrange the nodes in a line:
  vertices [1].pos.x = 0
  layer[ vertices [1] ] = #vertices
  for i=2,#vertices do
    local d = layered.ideal_sibling_distance(self.adjusted_bb, self.ugraph, vertices[i-1], vertices[i])
    vertices [i].pos.x = vertices[i-1].pos.x + d
    layer[ vertices [i] ] = #vertices
  end
\end{codeexample}

    Now comes the actual Huffman algorithm: Always find the vertices
    with a minimal probability\dots
    %
\begin{codeexample}[code only, tikz syntax=false]
  -- Now, do the Huffman thing...
  while #vertices > 1 do
    -- Find two minimum probabilities
    local min1, min2

    for i=1,#vertices do
      if not min1 or prop(vertices[i]) < prop(vertices[min1]) then
        min2 = min1
        min1 = i
      elseif not min2 or prop(vertices[i]) < prop(vertices[min2]) then
        min2 = i
      end
    end
\end{codeexample}
    %
    \dots and connect them with a new node. This new node gets the
    option |HuffmanNode|. It is now the job of the higher layers to map
    this option to something ``nice''.
    %
\begin{codeexample}[code only, tikz syntax=false]
    -- Create new node:
    local p = prop(vertices[min1]) + prop(vertices[min2])
    local v = InterfaceToAlgorithms.createVertex(self, { generated_options = {{key="HuffmanNode"}}})
    probability[v] = p
    layer[v] = #vertices-1
    v.pos.x = (vertices[min1].pos.x + vertices[min2].pos.x)/2
    vertices[#vertices + 1] = v

    InterfaceToAlgorithms.createEdge (self, v, vertices[min1],
        {generated_options = {{key="HuffmanLabel", value = "0"}}})
    InterfaceToAlgorithms.createEdge (self, v, vertices[min2],
        {generated_options = {{key="HuffmanLabel", value = "1"}}})

    table.remove(vertices, math.max(min1, min2))
    table.remove(vertices, math.min(min1, min2))
  end
\end{codeexample}
    %
    Ok, we are mainly done now. Finish by computing vertical placements
    and do formal cleanup.
    %
\begin{codeexample}[code only, tikz syntax=false]
  layered.arrange_layers_by_baselines(layers, self.adjusted_bb, self.ugraph)
end
\end{codeexample}

    In order to use the class, we have to make sure that, on the
    display layer, the options |HuffmanLabel| and |HuffmanNode| are
    defined. This is done by adding, for instance, the following to
    \tikzname:
    %
\begin{codeexample}[code only]
\pgfkeys{
  /graph drawing/HuffmanLabel/.style={
    /tikz/edge node={node[fill=white,font=\footnotesize,inner sep=1pt]{#1}}
  },
  /graph drawing/HuffmanNode/.style={
    /tikz/.cd,circle,inner sep=0pt,outer sep=0pt,draw,minimum size=3pt
  }
}
\end{codeexample}
  "]]
}


---

declare {
  key = "probability",
  type = "number",
  initial = "1",

  summary = [["
    The probability parameter. It is used by the Huffman algorithm to
    group nodes.
  "]]
}

-- Imports

local Storage    =  require 'pgf.gd.lib.Storage'

-- Storages

local probability = Storage.new()
local layer       = Storage.new()


function SimpleHuffman:run()
  -- Construct a Huffman tree on top of the vertices...

  -- Shorthand
  local function prop (v)
    return probability[v] or v.options['probability']
  end

  -- Copy the vertex table, since we are going to modify it:
  local vertices = {}
  for i,v in ipairs(self.ugraph.vertices) do
    vertices[i] = v
  end

  -- Now, arrange the nodes in a line:
  vertices [1].pos.x = 0
  layer[vertices [1]] = #vertices
  for i=2,#vertices do
    local d = layered.ideal_sibling_distance(self.adjusted_bb, self.ugraph, vertices[i-1], vertices[i])
    vertices [i].pos.x = vertices[i-1].pos.x + d
    layer[vertices [i]] = #vertices
  end

  -- Now, do the Huffman thing...
  while #vertices > 1 do
    -- Find two minimum probabilities
    local min1, min2

    for i=1,#vertices do
      if not min1 or prop(vertices[i]) < prop(vertices[min1]) then
        min2 = min1
        min1 = i
      elseif not min2 or prop(vertices[i]) < prop(vertices[min2]) then
        min2 = i
      end
    end

    -- Create new node:
    local p = prop(vertices[min1]) + prop(vertices[min2])
    local v = InterfaceToAlgorithms.createVertex(self, { generated_options = {{key="HuffmanNode"}}})
    probability[v] = p
    layer[v] = #vertices-1
    v.pos.x = (vertices[min1].pos.x + vertices[min2].pos.x)/2
    vertices[#vertices + 1] = v

    InterfaceToAlgorithms.createEdge (self, v, vertices[min1],
                                 {generated_options = {{key="HuffmanLabel", value = "0"}}})
    InterfaceToAlgorithms.createEdge (self, v, vertices[min2],
                                 {generated_options = {{key="HuffmanLabel", value = "1"}}})

    table.remove(vertices, math.max(min1, min2))
    table.remove(vertices, math.min(min1, min2))
  end

  layered.arrange_layers_by_baselines(layer, self.adjusted_bb, self.ugraph)
end

return SimpleHuffman
