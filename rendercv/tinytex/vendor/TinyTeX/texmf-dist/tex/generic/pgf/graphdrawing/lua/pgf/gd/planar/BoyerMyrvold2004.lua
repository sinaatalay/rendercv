
--[[
---Data structures---

Vertices from the original ugraph are referred to as input vertices.
The tables that contain vertex data relevant to the algorithm
are referred to as vertices.
A vertex table may have the following keys:

-sign
1 or -1, indicates whether this and all in the depth-first search
following vertices must be considered flipped
(i. e. adjacency lists reversed) in respect to the dfs parent

-childlist
A linked list containing all dfs children of the vertex whose virtual roots
have not yet been merged into the vertex, sorted by lowpoint

-adjlistlinks
A table with two fields with keys 0 and 1, containing the two half edges
of the vertex which lie on the external face of the graph
(if the vertex lies on the external face).
The half edge with key 0 lies in the 0-direction of the other half edge
and vice-versa
The two fields may hold the same half edge, if the vertex has degree one

-pertinentroots
A linked list containing all virtual roots of this vertex that are
pertinent during the current step

-inputvertex
The input vertex that corresponds to the vertex

-dfi
The depth-first search index (number of the step in the dfs at which
the vertex was discovered)

-dfsparent
The depth-first search parent (vertex from which the vertex was discovered
first in the dfs)

-leastancestor
Dfi of the vertex with lowest dfi that can be reached using one back edge
(non-tree edge)

-lowpoint
Dfi of the vertex with lowest dfi that can be reached using any number of
tree edges plus one back edge


A root vertex is a virtual vertex not contained in the original ugraph.
The root vertex represents another vertex in a biconnected component (block)
which is a child of the biconnected component the represented vertex is in.
The only field that it has in common with other vertices is the
adjacency list links array:

-isroot
always true, indicates that this vertex is a virtual root

-rootparent
The vertex which this root represents

-rootchild
The only dfs child of the original vertex which is contained in the
root verticis biconnected component

-adjlistlinks
See adjlistlinks of a normal vertex


A half edge is a table with the following fields:

-links
A table with two fields with keys 0 and 1, containing the neighboring
half edges in the adjacency list of the vertex these edges originate from.

-target
The vertex the half edge leads to

-twin
The twin half edge which connects the two vertices in the opposite direction

-shortcircuit
True if the half edge was inserted in order to make a short circuit for the
algorithm. The edge will be removed at the end.

The BoyerMyrvold2004 class has the following fields:

-inputgraph
The original ugraph given to the algorithm

-numvertices
The number of vertices of the graph

-vertices
The vertex table with depth-first search indices as keys

-verticesbyinputvertex
The vertex table with input vertices as keys

-verticesbylowpoint
The vertex table with low points as keys

-shortcircuitedges
An array of all short circuit half edges
(which may not be in the original graph and will be removed at the end)

--]]

local BM = {}
require("pgf.gd.planar").BoyerMyrvold2004 = BM

-- imports
local Storage = require "pgf.gd.lib.Storage"
local LinkedList = require "pgf.gd.planar.LinkedList"
local Embedding = require "pgf.gd.planar.Embedding"

-- create class properties
BM.__index = BM

function BM.new()
  local t = {}
  setmetatable(t, BM)
  return t
end

-- initializes some data structures at the beginning
-- takes the ugraph of the layout algorithm as input
function BM:init(g)
  self.inputgraph = g
  self.numvertices = #g.vertices
  self.vertices = {}
  self.verticesbyinputvertex = Storage.new()
  self.verticesbylowpoint = Storage.newTableStorage()
  self.shortcircuitedges = {}
  for _, inputvertex in ipairs(self.inputgraph.vertices) do
    local vertex = {
      sign = 1,
      childlist = LinkedList.new(),
      adjlistlinks = {},
      pertinentroots = LinkedList.new(),
      inputvertex = inputvertex,
    }
    setmetatable(vertex, Embedding.vertexmetatable)
    self.verticesbyinputvertex[inputvertex] = vertex
  end
end

--[[
local function nilmax(a, b)
  if a == nil then return b end
  if b == nil then return a end
  return math.max(a, b)
end

local function nilmin(a, b)
  if a == nil then return b end
  if b == nil then return a end
  return math.min(a, b)
end
--]]

-- the depth-first search of the preprocessing
function BM:predfs(inputvertex, parent)
  local dfi = #self.vertices + 1
  local vertex = self.verticesbyinputvertex[inputvertex]
  self.vertices[dfi] = vertex
  -- set the dfs infos in the vertex
  vertex.dfi = dfi
  vertex.dfsparent = parent
  vertex.leastancestor = dfi
  vertex.lowpoint = dfi
  -- find neighbors
  for _, arc in ipairs(self.inputgraph:outgoing(inputvertex)) do
    local ninputvertex = arc.head
    assert(ninputvertex ~= inputvertex, "Self-loop detected!")
    local nvertex = self.verticesbyinputvertex[ninputvertex]
    if nvertex.dfi == nil then
      -- new vertex discovered
      self:predfs(ninputvertex, vertex) -- recursive call
      vertex.lowpoint = math.min(vertex.lowpoint, nvertex.lowpoint)
    elseif parent and ninputvertex ~= parent.inputvertex then
      -- back edge found
      vertex.leastancestor = math.min(vertex.leastancestor, nvertex.dfi)
      vertex.lowpoint = math.min(vertex.lowpoint, nvertex.dfi)
    end
  end
  -- put vertex into lowpoint sort bucket
  table.insert(self.verticesbylowpoint[vertex.lowpoint], vertex)
end

-- the preprocessing at the beginning of the algorithm
-- does the depth-first search and the bucket sort for the child lists
function BM:preprocess()
  -- make dfs starting at an arbitrary vertex
  self:predfs(self.inputgraph.vertices[1])
  -- create separated child lists with bucket sort
  for i = 1, self.numvertices do
    for _, vertex in ipairs(self.verticesbylowpoint[i]) do
      if vertex.dfsparent then
        vertex.childlistelement
            = vertex.dfsparent.childlist:addback(vertex)
      end
    end
  end
end

-- adds tree edges and the corresponding virtual root vertices
-- of the currentvertex
function BM:add_trivial_edges(vertex)
  -- find all dfs children
  for _, arc in ipairs(self.inputgraph:outgoing(vertex.inputvertex)) do
    local nvertex = self.verticesbyinputvertex[arc.head]
    if nvertex.dfsparent == vertex then
      -- create root vertex
      local rootvertex = {
        isroot = true,
        rootparent = vertex,
        rootchild = nvertex,
        adjlistlinks = {},
        name = tostring(vertex) .. "^" .. tostring(nvertex)
      }
      setmetatable(rootvertex, Embedding.vertexmetatable)
      nvertex.parentroot = rootvertex
      -- create half edges
      local halfedge1 = {target = nvertex, links = {}}
      local halfedge2 = {target = rootvertex, links = {}}
      halfedge1.twin = halfedge2
      halfedge2.twin = halfedge1
      -- create circular adjacency lists
      halfedge1.links[0] = halfedge1
      halfedge1.links[1] = halfedge1
      halfedge2.links[0] = halfedge2
      halfedge2.links[1] = halfedge2
      -- create links to adjacency lists
      rootvertex.adjlistlinks[0] = halfedge1
      rootvertex.adjlistlinks[1] = halfedge1
      nvertex.adjlistlinks[0] = halfedge2
      nvertex.adjlistlinks[1] = halfedge2
    end
  end
end

-- for the external face vertex which was entered through link vin
-- returns the successor on the external face and the link through
-- which it was entered
local function get_successor_on_external_face(vertex, vin)
  local halfedge = vertex.adjlistlinks[1 - vin]
  local svertex = halfedge.target
  local sin
  if vertex.adjlistlinks[0] == vertex.adjlistlinks[1] then
    sin = vin
  elseif svertex.adjlistlinks[0].twin == halfedge then
    sin = 0
  else
    sin = 1
  end
  return svertex, sin
end

-- the "walkup", used to identify the pertinent subgraph,
-- i. e. the subgraph that contains end points of backedges
-- for one backedge this function will mark all virtual roots
-- as pertinent that lie on the path between the backedge and the current vertex
-- backvertex: a vertex that is an endpoint of a backedge to the current vertex
-- currentvertex: the vertex of the current step
-- returns a root vertex of the current step, if one was found
local function walkup(backvertex, currentvertex)
  local currentindex = currentvertex.dfi
  -- set the backedgeflag
  backvertex.backedgeindex = currentindex
  -- initialize traversal variables for both directions
  local x, xin, y, yin = backvertex, 1, backvertex, 0
  while x ~= currentvertex do
    if x.visited == currentindex or y.visited == currentindex then
      -- we found a path that already has the pertinent roots marked
      return nil
    end
    -- mark vertices as visited for later calls
    x.visited = currentindex
    y.visited = currentindex

    -- check for rootvertex
    local rootvertex
    if x.isroot then
      rootvertex = x
    elseif y.isroot then
      rootvertex = y
    end
    if rootvertex then
      local rootchild = rootvertex.rootchild
      local rootparent = rootvertex.rootparent
      if rootvertex.rootparent == currentvertex then
        -- we found the other end of the back edge
        return rootvertex
      elseif rootchild.lowpoint < currentindex then
        -- the block we just traversed is externally active
        rootvertex.pertinentrootselement
            = rootparent.pertinentroots:addback(rootvertex)
      else
        -- the block we just traversed is internally active
        rootvertex.pertinentrootselement
            = rootparent.pertinentroots:addfront(rootvertex)
      end
      -- jump to parent block
      x, xin, y, yin = rootvertex.rootparent, 1, rootvertex.rootparent, 0
    else
      -- just continue on the external face
      x, xin = get_successor_on_external_face(x, xin)
      y, yin = get_successor_on_external_face(y, yin)
    end
  end
end

-- inverts the adjacency of a vertex
-- i. e. reverses the order of the adjacency list and flips the links
local function invert_adjacency(vertex)
  -- reverse the list
  for halfedge in Embedding.adjacency_iterator(vertex.adjlistlinks[0]) do
    halfedge.links[0], halfedge.links[1]
        = halfedge.links[1], halfedge.links[0]
  end
  -- flip links
  vertex.adjlistlinks[0], vertex.adjlistlinks[1]
      = vertex.adjlistlinks[1], vertex.adjlistlinks[0]
end

-- merges two blocks by merging the virtual root of the child block
-- into it's parent, while making sure the external face stays consistent
-- by flipping the root block if needed
-- mergeinfo contains four fields:
-- root - the virtual root vertex
-- parent - it's parent
-- rout - the link of the root through which we have exited it
--        during the walkdown
-- pin - the link of the parent through which we have entered it
--       during the walkdown
local function mergeblocks(mergeinfo)
  local root = mergeinfo.root
  local parent = mergeinfo.parent
  local rout = mergeinfo.rootout
  local pin = mergeinfo.parentin
  if pin == rout then
    -- flip required
    invert_adjacency(root)
    root.rootchild.sign = -1
    --rout = 1 - rout -- not needed
  end

  -- redirect edges of the root vertex
  for halfedge in Embedding.adjacency_iterator(root.adjlistlinks[0]) do
    halfedge.twin.target = parent
  end

  -- remove block from data structures
  root.rootchild.parentroot = nil
  parent.pertinentroots:remove(root.pertinentrootselement)
  parent.childlist:remove(root.rootchild.childlistelement)

  -- merge adjacency lists
  parent.adjlistlinks[0].links[1] = root.adjlistlinks[1]
  parent.adjlistlinks[1].links[0] = root.adjlistlinks[0]
  root.adjlistlinks[0].links[1] = parent.adjlistlinks[1]
  root.adjlistlinks[1].links[0] = parent.adjlistlinks[0]
  parent.adjlistlinks[pin] = root.adjlistlinks[pin]
end

-- inserts a half edge pointing to "to" into the adjacency list of "from",
-- replacing the link "linkindex"
local function insert_half_edge(from, linkindex, to)
  local halfedge = {target = to, links = {}}
  halfedge.links[    linkindex] = from.adjlistlinks[    linkindex]
  halfedge.links[1 - linkindex] = from.adjlistlinks[1 - linkindex]
  from.adjlistlinks[    linkindex].links[1 - linkindex] = halfedge
  from.adjlistlinks[1 - linkindex].links[    linkindex] = halfedge
  from.adjlistlinks[linkindex] = halfedge
  return halfedge
end

-- connect the vertices x and y through the links xout and yin
-- if shortcircuit is true, the edge will be marked as a short circuit edge
-- and removed at the end of the algorithm
function BM:embed_edge(x, xout, y, yin, shortcircuit)
  -- create half edges
  local halfedgex = insert_half_edge(x, xout, y)
  local halfedgey = insert_half_edge(y, yin, x)
  halfedgex.twin = halfedgey
  halfedgey.twin = halfedgex
  -- short circuit handling
  if shortcircuit then
    halfedgex.shortcircuit = true
    halfedgey.shortcircuit = true
    table.insert(self.shortcircuitedges, halfedgex)
    table.insert(self.shortcircuitedges, halfedgey)
  end
end

-- returns true if the given vertex is pertinent at the current step
local function pertinent(vertex, currentindex)
  return vertex.backedgeindex == currentindex
      or not vertex.pertinentroots:empty()
end

-- returns true if the given vertex is externally active at the current step
local function externally_active(vertex, currentindex)
  return vertex.leastancestor < currentindex
      or (not vertex.childlist:empty()
      and vertex.childlist:first().lowpoint < currentindex)
end

-- the "walkdown", which merges the pertinent subgraph and embeds
-- back and short circuit edges
-- childrootvertex - a root vertex of the current vertex
--                   which the walkdown will start at
-- currentvertex - the vertex of the current step
function BM:walkdown(childrootvertex, currentvertex)
  local currentindex = currentvertex.dfi
  local mergestack = {}
  local numinsertededges = 0 -- to return the number for count check
  -- two walkdowns into both directions
  for vout = 0,1 do
    -- initialize the traversal variables
    local w, win = get_successor_on_external_face(childrootvertex, 1 - vout)
    while w ~= childrootvertex do
      if w.backedgeindex == currentindex then
        -- we found a backedge endpoint
        -- merge all pertinent roots we found
        while #mergestack > 0 do
          mergeblocks(table.remove(mergestack))
        end
        -- embed the back edge
        self:embed_edge(childrootvertex, vout, w, win)
        numinsertededges = numinsertededges + 1
        w.backedgeindex = 0 -- this shouldn't be necessary
      end
      if not w.pertinentroots:empty() then
        -- we found a pertinent vertex with child blocks
        -- create merge info for the later merge
        local mergeinfo = {}
        mergeinfo.parent = w
        mergeinfo.parentin = win
        local rootvertex = w.pertinentroots:first()
        mergeinfo.root = rootvertex
        -- check both directions for active vertices
        local x, xin = get_successor_on_external_face(rootvertex, 1)
        local y, yin = get_successor_on_external_face(rootvertex, 0)
        local xpertinent = pertinent(x, currentindex)
        local xexternallyactive = externally_active(x, currentindex)
        local ypertinent = pertinent(y, currentindex)
        local yexternallyactive = externally_active(y, currentindex)
        -- chose the direction with the best vertex
        if xpertinent and not xexternallyactive then
          w, win = x, xin
          mergeinfo.rootout = 0
        elseif ypertinent and not yexternallyactive then
          w, win = y, yin
          mergeinfo.rootout = 1
        elseif xpertinent then
          w, win = x, xin
          mergeinfo.rootout = 0
        else
          w, win = y, yin
          mergeinfo.rootout = 1
        end
        -- this is what the paper says, but it might cause problems
        -- not sure though...
        --[[if w == x then
            mergeinfo.rootout = 0
        else
            mergeinfo.rootout = 1
        end--]]
        table.insert(mergestack, mergeinfo)
      elseif not pertinent(w, currentindex)
          and not externally_active(w, currentindex) then
        -- nothing to see here, just continue on the external face
        w, win = get_successor_on_external_face(w, win)
      else
        -- this is a stopping vertex, walkdown will end here
        -- paper puts this into the if,
        -- but this should always be the case, i think
        assert(childrootvertex.rootchild.lowpoint < currentindex)
        if #mergestack == 0 then
          -- we're in the block we started at, so we embed a back edge
          self:embed_edge(childrootvertex, vout, w, win, true)
        end
        break
      end
    end
    if #mergestack > 0 then
      -- this means, there is a pertinent vertex blocked by stop vertices,
      -- so the graph is not planar and we can skip the second walkdown
      break
    end
  end
  return numinsertededges
end

-- embeds the back edges for the current vertex
-- walkup and walkdown are called from here
-- returns true, if all back edges could be embedded
function BM:add_back_edges(vertex)
  local pertinentroots = {} -- not in the paper
  local numbackedges = 0
  -- find all back edges to vertices with lower dfi
  for _, arc in ipairs(self.inputgraph:outgoing(vertex.inputvertex)) do
    local nvertex = self.verticesbyinputvertex[arc.head]
    if nvertex.dfi > vertex.dfi
        and nvertex.dfsparent ~= vertex
        and nvertex ~= vertex.dfsparent then
      numbackedges = numbackedges + 1
      -- do the walkup
      local rootvertex = walkup(nvertex, vertex)
      if rootvertex then
        -- remember the root vertex the walkup found, so we don't
        -- have to call the walkdown for all root vertices
        -- (or even know what the root vertices are)
        table.insert(pertinentroots, rootvertex)
      end
    end
  end
  -- for all root vertices the walkup found
  local insertededges = 0
  while #pertinentroots > 0 do
    -- do the walkdown
    insertededges = insertededges
        + self:walkdown(table.remove(pertinentroots), vertex)
  end
  if insertededges ~= numbackedges then
    -- not all back edges could be embedded -> graph is not planar
    return false
  end
  return true
end

-- the depth-first search of the postprocessing
-- flips the blocks according to the sign field
function BM:postdfs(vertex, sign)
  sign = sign or 1
  local root = vertex.parentroot
  if root then
    sign = 1
  else
    sign = sign * vertex.sign
  end

  if sign == -1 then
    -- number of flips is odd, so we need to flip here
    invert_adjacency(vertex)
  end

  -- for all dfs children
  for _, arc in ipairs(self.inputgraph:outgoing(vertex.inputvertex)) do
    local nvertex = self.verticesbyinputvertex[arc.head]
    if nvertex.dfsparent == vertex then
      -- recursive call
      self:postdfs(nvertex, sign)
    end
  end
end

-- the postprocessing at the end of the algorithm
-- calls the post depth-first search,
-- removes the short circuit edges from the adjacency lists,
-- adjusts the links of the vertices,
-- merges root vertices
-- and cleans up the vertices
function BM:postprocess()
  -- flip components
  self:postdfs(self.vertices[1])

  -- unlink the short circuit edges
  for _, halfedge in ipairs(self.shortcircuitedges) do
    halfedge.links[0].links[1] = halfedge.links[1]
    halfedge.links[1].links[0] = halfedge.links[0]
  end

  -- vertex loop
  local rootvertices = {}
  local edgetoface = {}
  for _, vertex in ipairs(self.vertices) do
    -- check for root vertex and save it
    local root = vertex.parentroot
    if root then
      table.insert(rootvertices, root)
    end

    -- clean up links and create adjacency matrix
    local link = vertex.adjlistlinks[0]
    local adjmat = {}
    vertex.adjmat = adjmat
    if link then
      -- make sure the link points to a half edge
      -- that is no short circuit edge
      while link.shortcircuit do
        link = link.links[0]
      end
      -- create link
      vertex.link = link

      -- create adjacency matrix
      for halfedge in Embedding.adjacency_iterator(link) do
        setmetatable(halfedge, Embedding.halfedgemetatable)
        local target = halfedge.target
        if target.isroot then
          target = target.rootparent
        end
        adjmat[target] = halfedge
      end
    end

    -- clean up vertex
    vertex.sign = nil
    vertex.childlist = nil
    vertex.adjlistlinks = nil
    vertex.pertinentroots = nil
    vertex.dfi = nil
    vertex.dfsparent = nil
    vertex.leastancestor = nil
    vertex.lowpoint = nil
    vertex.parentroot = nil
  end

  -- root vertex loop
  for _, root in ipairs(rootvertices) do
    -- make sure the links point to a half edges
    -- that are no short circuit edge
    local link = root.adjlistlinks[0]
    while link.shortcircuit do
        link = link.links[0]
    end

    -- merge into parent
    local rootparent = root.rootparent
    local parentlink = rootparent.link
    local adjmat = rootparent.adjmat
    for halfedge in Embedding.adjacency_iterator(link) do
      setmetatable(halfedge, Embedding.halfedgemetatable)
      halfedge.twin.target = rootparent
      adjmat[halfedge.target] = halfedge
    end
    if parentlink == nil then
      assert(rootparent.link == nil)
      rootparent.link = link
    else
      -- merge adjacency lists
      parentlink.links[0].links[1] = link
      link.links[0].links[1] = parentlink
      local tmp = link.links[0]
      link.links[0] = parentlink.links[0]
      parentlink.links[0] = tmp
    end
  end
end

-- the entry point of the algorithm
-- returns the array of vertices
-- the vertices now only contain the inputvertex field
-- and a field named "link" which contains an arbitrary half edge
-- from the respective adjacency list
-- the adjacency lists are in a circular order in respect to the plane graph
function BM:run()
  self:preprocess()
  -- main loop over all vertices from lowest dfi to highest
  for i = self.numvertices, 1, -1 do
    local vertex = self.vertices[i]
    self:add_trivial_edges(vertex)
    if not self:add_back_edges(vertex) then
      -- graph not planar
      return nil
    end
  end
  self:postprocess()
  local embedding = Embedding.new()
  embedding.vertices = self.vertices
  return embedding
end

return BM
