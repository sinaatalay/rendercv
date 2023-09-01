-- Copyright 2013 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$




local DistanceMatrix = {}


-- Imports
local InterfaceToAlgorithms = require("pgf.gd.interface.InterfaceToAlgorithms")
local declare = InterfaceToAlgorithms.declare


---

declare {
  key = "distance matrix vertices",
  type = "string",

  summary = [["
    A list of vertices that are used in the parsing of the
    |distance matrix| key. If this key is not used at all, all
    vertices of the graph will be used for the computation of a
    distance matrix.
  "]],

  documentation = [["
    The vertices must be separated by spaces and/or
    commas. For vertices containing spaces or commas, the vertex
    names may be surrounded by single or double quotes (as in
    Lua). Typical examples are |a, b, c| or |"hello world", 'foo'|.
  "]]
}



---

declare {
  key = "distance matrix",
  type = "string",

  summary = [["
    A distance matrix specifies ``desired distances'' between
    vertices in a graph. These distances are used, in particular, in
    algorithms for computing phylogenetic trees.
  "]],

  documentation = [["
    When this key is parsed, the key |distance matrix vertices| is
    considered first. It is used to determine a list of vertices
    for which a distance matrix is computed, see that key for
    details. Let $n$ be the number of vertices derived from that
    key.

    The string passed to the |distance matrix| key is basically
    a sequence of numbers that are used to fill an $n \times n$
    matrix. This works as follows: We keep track of a \emph{current
    position $p$} in the matrix, starting at the upper left corner
    of the matrix. We read the numbers in the string
    one by one, write it to the current position of the matrix, and
    advance the current position by going right one step; if we go
    past the right end of the matrix, we ``wrap around'' by going
    back to the left border of the matrix, but one line down. If we
    go past the bottom of the matrix, we start at the beginning once
    more.

    This basic behavior can be modified in different ways. First,
    when a number is followed by a semicolon instead of a comma or a
    space (which are the ``usual'' ways of indicating the end of a
    number), we immediately go down to the next line. Second,
    instead of a number you can directly provide a \emph{position}
    in the matrix and the current position will be set to this
    position. Such a position information is detected by a
    greater-than sign (|>|). It must be followed by
    %
    \begin{itemize}
      \item a number or a vertex name or
      \item a number or a vertex name, a comma, and another number or
        vertex name or
      \item a comma and a number and a vertex name.
    \end{itemize}
    %
    Examples of the respective cases are |>1|, |>a,b|, and
    |>,5|. The semantics is as follows: In all cases, if a vertex
    name rather than a number is given, it is converted into a
    number (namely the index of the vertex inside the matrix). Then,
    in the first case, the column of the current position is set to
    the given number; in the second case, the columns is set to the
    first number and the column is set to the second number; and in
    the third case only the row is set to the given number. (This
    idea is that following the |>|-sign comes a ``coordinate pair''
    whose components are separated by a comma, but part of that pair
    may be missing.) If a vertex name contains special symbols like
    a space or a comma, you must surround it by single or double
    quotation marks (as in Lua).

    Once the string has been parsed completely, the matrix may be
    filled only partially. In this case, for each missing entry
    $(x,y)$, we try to set it to the value of the entry $(y,x)$,
    provided that entry is set. If neither are set, the entry is set
    to $0$.

    Let us now have a look at several examples that all produce the
    same matrix. The vertices are |a|, |b|, |c|.
    %
\begin{codeexample}[code only, tikz syntax=false]
0, 1, 2
1, 0, 3
2, 3, 0
\end{codeexample}
    %
\begin{codeexample}[code only, tikz syntax=false]
0 1 2 1 0 3 2 3 0
\end{codeexample}
    %
\begin{codeexample}[code only, tikz syntax=false]
;
1;
2 3
\end{codeexample}
    %
\begin{codeexample}[code only, tikz syntax=false]
>,b 1; 2 3
\end{codeexample}
    %
\begin{codeexample}[code only, tikz syntax=false]
>b 1 2 >c 3
\end{codeexample}
  "]]
}


---

declare {
  key = "distances",
  type = "string",

  summary = [["
    This key is used to specify the ``desired distances'' between
    a vertex and the other vertices in a graph.
  "]],

  documentation = [["
    This key works similar to the |distance matrix| key, only it is
    passed to a vertex instead of to a whole graph. The syntax is
    the same, only the notion of different ``rows'' is not
    used. Here are some examples that all have the same effect,
    provided the nodes are |a|, |b|, and |c|.
    %
\begin{codeexample}[code only, tikz syntax=false]
0, 1, 2
\end{codeexample}
    %
\begin{codeexample}[code only, tikz syntax=false]
0 1 2
\end{codeexample}
    %
\begin{codeexample}[code only, tikz syntax=false]
>b 1 2
\end{codeexample}
    %
\begin{codeexample}[code only, tikz syntax=false]
>c 2, >b 1
\end{codeexample}
  "]]
}



local function to_index(s, indices)
  if s and s ~= "" then
    if s:sub(1,1) == '"' then
      local _, _, m = s:find('"(.*)"')
      return indices[InterfaceToAlgorithms.findVertexByName(m)]
    elseif s:sub(1,1) == "'" then
      local _, _, m = s:find("'(.*)'")
      return indices[InterfaceToAlgorithms.findVertexByName(m)]
    else
      local num = tonumber(s)
      if not num then
        return indices[InterfaceToAlgorithms.findVertexByName(s)]
      else
        return num
      end
    end
  end
end

local function compute_indices(vertex_string, vertices)
  local indices = {}

  if not vertex_string then
    for i,v in ipairs(vertices) do
      indices[i] = v
      indices[v] = i
    end
  else
    -- Ok, need to parse the vertex_string. Sigh.
    local pos = 1
    while pos <= #vertex_string do
      local start = vertex_string:sub(pos,pos)
      if not start:find("[%s,]") then
        local _, vertex
        if start == '"' then
          _, pos, vertex = vertex_string:find('"(.-)"', pos)
        elseif start == "'" then
          _, pos, vertex = vertex_string:find("'(.-)'", pos)
        else
          _, pos, vertex = vertex_string:find("([^,%s'\"]*)", pos)
        end
        local v = assert(InterfaceToAlgorithms.findVertexByName(vertex), "unknown vertex name '" .. vertex .. "'")
        indices [#indices + 1] = v
        indices [v]            = #indices
      end
      pos = pos + 1
    end
  end

  return indices
end


---
-- Compute a distance matrix based on the values of a
-- |distance matrix| and a |distance matrix vertices|.
--
-- @param matrix_string A distance matrix string
-- @param vertex_string A distance matrix vertex string
-- @param vertices An array of all vertices in the graph.
--
-- @return A distance matrix. This matrix will contain both a
-- two-dimensional array (accessed through numbers) and also a
-- two-dimensional hash table (accessed through vertex indices). Thus,
-- you can write both |m[1][1]| and also |m[v][v]| to access the first
-- entry of this matrix, provided |v == vertices[1]|.
-- @return An index vector. This is an array of the vertices
-- identified for the |vertex_string| parameter.

function DistanceMatrix.computeDistanceMatrix(matrix_string, vertex_string, vertices)
  -- First, we create a table of the vertices we need to consider:
  local indices = compute_indices(vertex_string, vertices)

  -- Second, build matrix.
  local n = #indices
  local m = {}
  for i=1,n do
    m[i] = {}
  end

  local x = 1
  local y = 1
  local pos = 1
  -- Start scanning the matrix_string
  while pos <= #matrix_string do
    local start = matrix_string:sub(pos,pos)
    if not start:find("[%s,]") then
      if start == '>' then
        local _, parse
        _, pos, parse = matrix_string:find(">([^%s>;]*)", pos)
        local a, b
        if parse:find(",") then
          _,_,a,b = parse:find("(.*),(.*)")
        else
          a = parse
        end
        x = to_index(a, indices) or x
        y = to_index(b, indices) or y
      elseif start == ';' then
        x = 1
        y = y + 1
      elseif start == ',' then
        x = x + 1
      else
        local _, n
        _, pos, n = matrix_string:find("([^,;%s>]*)", pos)
        local num = assert(tonumber(n), "number expected in distance matrix")
        m[x][y] = num
        x = x + 1
        -- Skip everything up to first comma:
        _, pos = matrix_string:find("(%s*,?)", pos+1)
      end
    end
    pos = pos + 1
    if x > n then
      x = 1
      y = y + 1
    end
    if y > n then
      y = 1
    end
  end

  -- Fill up
  for x=1,n do
    for y=1,n do
      if not m[x][y] then
        m[x][y] = m[y][x] or 0
      end
    end
  end

  -- Copy to index version
  for x=1,n do
    local v = indices[x]
    m[v] = {}
    for y=1,n do
      local u = indices[y]
      m[v][u] = m[x][y]
    end
  end

  return m, indices
end




---
-- Compute a distance vector. See the key |distances| for details.
--
-- @param vector_string A distance vector string
-- @param vertex_string A distance matrix vertex string
-- @param vertices An array of all vertices in the graph.
--
-- @return A distance vector. Like a distance matrix, this vector will
-- double indexed, once by numbers and once be vertex objects.
-- @return An index vector. This is an array of the vertices
-- identified for the |vertex_string| parameter.

function DistanceMatrix.computeDistanceVector(vector_string, vertex_string, vertices)
  -- First, we create a table of the vertices we need to consider:
  local indices = compute_indices(vertex_string, vertices)

  -- Second, build matrix.
  local n = #indices
  local m = {}
  local x = 1
  local pos = 1
  -- Start scanning the vector_string
  while pos <= #vector_string do
    local start = vector_string:sub(pos,pos)
    if not start:find("[%s,]") then
      if start == '>' then
        local _, parse
        _, pos, parse = vector_string:find(">([^%s>;]*)", pos)
        x = to_index(parse, indices) or x
      elseif start == ',' then
        x = x + 1
      else
        local _, n
        _, pos, n = vector_string:find("([^,;%s>]*)", pos)
        local num = assert(tonumber(n), "number expected in distance matrix")
        m[x] = num
        x = x + 1
        -- Skip everything up to first comma:
        _, pos = vector_string:find("(%s*,?)", pos+1)
      end
    end
    pos = pos + 1
    if x > n then
      x = 1
    end
  end

  -- Fill up
  for x=1,n do
    m[x] = m[x] or 0
    m[indices[x]] = m[x]
  end

  return m, indices
end



---
-- Compute a distance matrix for a graph that incorporates all
-- information stored in the different options of the graph and the
-- vertices.
--
-- @param graph A digraph object.
--
-- @return A distance matrix for all vertices of the graph.

function DistanceMatrix.graphDistanceMatrix(digraph)
  local vertices = digraph.vertices
  local n = #vertices
  local m = {}
  for i,v in ipairs(vertices) do
    m[i] = {}
    m[v] = {}
  end

  local indices = {}
  for i,v in ipairs(vertices) do
    indices[i] = v
    indices[v] = i
  end

  if digraph.options['distance matrix'] then
    local sub, vers = DistanceMatrix.computeDistanceMatrix(
      digraph.options['distance matrix'],
      digraph.options['distance matrix vertices'],
      vertices
    )

    for x=1,#vers do
      for y=1,#vers do
        m[vers[x]][vers[y]] = sub[x][y]
      end
    end
  end

  for i,v in ipairs(vertices) do
    if v.options['distances'] then
      local sub, vers = DistanceMatrix.computeDistanceVector(
        v.options['distances'],
        v.options['distance matrix vertices'],
        vertices
      )

      for x=1,#vers do
        m[vers[x]][v] = sub[x]
      end
    end
  end

  -- Fill up number versions:
  for x,vx in ipairs(vertices) do
    for y,vy in ipairs(vertices) do
      m[x][y] = m[vx][vy]
    end
  end

  return m
end



return DistanceMatrix
