-- Copyright 2015 by Malte Skambath
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--

-- Imports
local lib      = require "pgf.gd.lib"

local Vertex   = require "pgf.gd.model.Vertex"
local Digraph  = require "pgf.gd.model.Digraph"
local Storage  = require "pgf.gd.lib.Storage"


local declare  = require("pgf.gd.interface.InterfaceToAlgorithms").declare

---
-- Each |Supergraph| instance is a |Digraph| instance which represents
-- the graph by union operation on all graphs G_i of an evolving graph
-- $G=(G_1, G_2, \dots, G_n)$. Additional to that all references to
-- the snapshot-graphs are shared such that is possible to get access
-- to all vertices for each snapshot graph in a sequence. A vertex of
-- an evolving graph may exists at different times, thus in in
-- different snapshots. Each vertex will be a vertex in the supergraph
-- and if there is a single snapshot in which two vertices are
-- connected by an edge they are connected in the supergraph.
--
-- Note that in \tikzname\ a \emph{node} is more than a single dot. A node
-- has a content and different properties like background-color or a
-- shape. Formally this can be modeled by function mapping vertices
-- to their properties. For evolving graphs this could be done in the
-- same way. As this is difficult to be realized in PGF  because there
-- is no basic support for time dependent properties on nodes, each
-- vertex will be displayed over time by different single
-- (snapshot-)nodes which can have different visual properties. This
-- means for a vertex which we call |supervertex| in the following we
-- will have a (snapshot-)node for each time stamp.
--
-- \medskip
-- \noindent\emph{Snapshots.}
-- Since an evolving graph is a sequence of different snapshot-graphs
-- $G_i$ each snapshot is assigned to a time
--
--
-- @field vertex_snapshots This storage maps each pgf-node to the snapshots
--        in which they are visible.
--
-- @field supervertices This storage maps each pgf-node to its supervertex
--        which represents all pgf-vertices assigned to the same node
--
-- @field supervertices_by_id This storage maps a node identifier to the
--        related supervertex such that PGF-nodes which belonging to
--        the same superverticex can be identified
--
-- @field snapshots An array of all snapshots. Sorted in ascending order
-- over the timestamps of the snapshots.
--
-- @field arc_snapshots A table storing all snapshots of a supervertex in which
--        the related nodes are connected. Using a snapshot as key you can check
--        if a given snapshot is in the array.
--
--        Assume we want to iterate over all snapshots
--        for a certain pair of supernodes in which they are connected
--        by an arc. The arc_snapshots  storage helps in this case:
--        %
--        \begin{codeexample}[code only, tikz syntax=false]
--           local supergraph = Supergraph.generateSupergraph(self.digraph)
--           local u = supergraph.vertices[1]
--           local v = supergraph.vertices[2]
--
--           local snapshots = supergraph.arc_snapshots[supergraph:arc(u, v)]
--           for _, snapshot in ipairs(snapshots) do
--             do_something(snapshot)
--           end
--        \end{codeexample}
--
local Supergraph = lib.class { base_class = Digraph }

-- Namespace
--require("pgf.gd.experimental.evolving").Supergraph = Supergraph

Supergraph.__index =
  function (t, k)
    if k == "arcs" then
      return Digraph.__index(t,k)
    else
      return rawget(Supergraph, k) or rawget(Digraph, k)
    end
  end

function Supergraph.new(initial)
  local supergraph = Digraph.new(initial)
  setmetatable(supergraph, Supergraph)

  supergraph.vertex_snapshots          = Storage.new()
  supergraph.supervertices       = Storage.new()
  supergraph.supervertices_by_id = {}
  supergraph.arc_snapshots       = Storage.newTableStorage()

  return supergraph

end


local get_snapshot

---
-- Generate or extract a snapshot instance for a given snapshot time.
--
-- @param snapshots  An array of all existing snapshots
-- @param timestamps A table which maps known timestamps to their
-- related snapshots
-- @param ugraph     The ugraph of the underlying graph structure
-- @param snapshot_time
--
-- @return The snapshot instance found in the snapshots array for the
-- wanted timestamp snapshot_time if it doesn't exists a new snapshot
-- will be generated and added to the arrays
--
function get_snapshot(snapshots, timestamps, ugraph, snapshot_time)
  local snapshot
  local snapshot_idx = timestamps[snapshot_time]

  if not snapshot_idx then
    -- store snapshot if it doesn't exists
    snapshot_idx = timestamps.n + 1
    timestamps[snapshot_time] = snapshot_idx
    timestamps.n = timestamps.n + 1
    snapshot = Digraph.new {
      syntactic_digraph = ugraph.syntactic_digraph,
      options           = ugraph.options
    }
    snapshot.timestamp = snapshot_time
    snapshots[snapshot_idx] = snapshot
  else
    snapshot = snapshots[snapshot_idx]
  end
  assert(snapshot~=nil, "an unexpected error occurred")
  return snapshot
end


---
-- Generate a new supergraph to describe the whole evolving graph by
-- collecting all temporal information from the digraph and the node
-- options. All nodes in the |digraph| require a |snapshot| and
-- a |supernode| option. To identify a (snapshot-)node with its
-- supernode and snapshot.
--
-- @param digraph
--
-- @return The supergraph which is a |Digraph| that has a supervertex
-- for each set of snapshot-vertices with the same |supernode|
-- attribute.
--
function Supergraph.generateSupergraph(digraph)
  local new_supergraph
  new_supergraph = Supergraph.new {
    syntactic_digraph = digraph.syntactic_digraph,
    options           = digraph.options,
    digraph           = digraph,
  }

  -- array to store the supervertices for a given vertex name
  local local_snapshots = {}       -- array to store each snapshot graphs

  local timestamps = { n = 0 }     -- set of snapshot times

  -- separate and assign vertices to their snapshots and supervertices
  for i,vertex in ipairs(digraph.vertices) do
    local snapshot_time  = assert(vertex.options["snapshot"], "Missing option 'snapshot' for vertex ".. vertex.name ..". ")
    local supernode_name = assert(vertex.options["supernode"], "Missing option 'supernode' for vertex"..vertex.name..". ")

    local snapshot    = get_snapshot(local_snapshots, timestamps, digraph, snapshot_time)
    local supervertex = new_supergraph.supervertices_by_id[supernode_name]

    if not supervertex then
      -- first appearance of the supernode id
      supervertex = Vertex.new {
        kind = "super",
        name = supernode_name
      }
      supervertex.snapshots = {}
      supervertex.subvertex = {}
      new_supergraph.supervertices_by_id[supernode_name] = supervertex
      new_supergraph:add{supervertex}

      supervertex.options = {}
      supervertex.options = vertex.options
    end

    snapshot:add{vertex}

    new_supergraph.supervertices[vertex] = supervertex
    new_supergraph.vertex_snapshots[vertex] = snapshot
    new_supergraph:addSnapshotVertex(supervertex, snapshot, vertex)
  end

  -- Create edges
  for i, e in ipairs(digraph.arcs) do
    local u,v = e.tail, e.head
    local snapshot_tail = new_supergraph.vertex_snapshots[e.tail]
    local snapshot_head = new_supergraph.vertex_snapshots[e.head]

    assert(snapshot_head == snapshot_tail, "Arcs must connect nodes that exist at the same time.")

    -- connect in the snapshot graph
    local arc = snapshot_tail:connect(u,v)

    -- connect in the supergraph:
    local super_tail = new_supergraph.supervertices[u]
    local super_head = new_supergraph.supervertices[v]

    new_supergraph:assignToSuperarc(super_tail, super_head, snapshot_tail)
  end

  -- snapshots in temporal order
  table.sort(local_snapshots,
    function(s1,s2)
      return s1.timestamp < s2.timestamp
    end )

  local previous_snapshot

  for i,s in ipairs(local_snapshots) do
    local start = -math.huge
    if previous_snapshot then
      start = (s.timestamp - previous_snapshot.timestamp) / 2 + previous_snapshot.timestamp
      previous_snapshot.interval.to = start
    end
    s.interval = { from = start , to = math.huge }
    previous_snapshot = s
  end

  new_supergraph.snapshots = local_snapshots
  new_supergraph.snapshots_indices = Storage.new()

  for i, s in ipairs(new_supergraph.snapshots) do
    new_supergraph.snapshots_indices[s] = i
  end

  return new_supergraph
end


function Supergraph:getSnapshotStaticDuration(snapshot)
  assert(snapshot, "a snapshot as parameter expected, but got nil")
  local idur = snapshot.interval.to - snapshot.interval.from
  assert(idur, "unexpected nil-value")
  local d1 = snapshot.interval.to - snapshot.timestamp
  local d2 = snapshot.timestamp - snapshot.interval.from
  local dm = math.min(d1,d2)
  if (idur >= math.huge and dm < math.huge) then
    return dm        -- [-\infty,t] or [t,\infty]
  elseif idur >= math.huge then
    return 0         -- only one snapshot [-\infty,\infty]
  else
    return d1 + d2   -- [t_1, t_2]
  end
end

---
-- Get the durations of the graph in which snapshots are given which is exactly
-- the time between the first and the last defined snapshot
--
-- @return The time between the last and first snapshot in seconds
function Supergraph:getDuration()
  local first_snapshot = self.snapshots[1]
  local last_snapshot  = self.snapshots[#self.snapshots]
  return last_snapshot.timestamp - first_snapshot.timestamp
end

---
--
-- @return The ratio of the time of a snapshot related to the global duration of the whole
--          evolving trees. (The time between the last and first snapshot)
function Supergraph:getSnapshotRelativeDuration(snapshot)
  if self:getDuration() == 0 then
    return 1
  else
    return self:getSnapshotStaticDuration(snapshot) / self:getDuration()
  end
end

---
-- Give the supervertex for a certain pgf-vertex (vertex of a snapshot)
--
-- @param vertex A vertex of a snapshot.
--
-- @return A supervertex in the supergraph for the given vertex, nil if no
-- supervertex was assigned before.
--
function Supergraph:getSupervertex(vertex)
  assert(vertex, "vertex required")
  assert(self.supervertices, "supervertex table is not defined")
  return self.supervertices[vertex]
end

function Supergraph:getSuperarc(arc)
  local superhead = self:getSupervertex(arc.head)
  local supertail = self:getSupervertex(arc.tail)
  local arc = assert(self:arc(supertail, superhead),"unexpected problem")
  return arc
end

function Supergraph:getSnapshots(supervertex)
  return supervertex.snapshots
end

---
-- Find the snapshot-instance for a given pgf-vertex
-- (which is a vertex for one certain snapshot)
--
-- @param vertex A vertex for which you want to get the related snapshot
--
-- @return The snapshot which contains the given vertex as vertex.
function Supergraph:getSnapshot(vertex)
  return self.vertex_snapshots[vertex]
end

---
-- For a given supervertex get the related vertex for a snapshot
--
-- @param supervertex
--
-- @param snapshot
--
-- @return The vertex of the supervertex at the specified snapshot
--
function Supergraph:getSnapshotVertex(supervertex, snapshot)
  assert(supervertex, "supervertex must not be nil")
  assert(snapshot,    "snapshot must not be nil")
  return supervertex.subvertex[snapshot]
end


function Supergraph:consecutiveSnapshots(snapshot1, snapshot2, n)
  assert(snapshot1 and snapshot2, "no snapshot passed")
  local idx1 = self.snapshots_indices[snapshot1] --or -1
  local idx2 = self.snapshots_indices[snapshot2] --or -1
  local d = n or 1

  return (idx2-idx1 <= d) or (idx1-idx2 <= d)
end

function Supergraph:consecutive(vertex1, vertex2, n)
  local s1 = self:getSnapshot(vertex1)
  local s2 = self:getSnapshot(vertex2)
  return self:consecutiveSnapshots(s1, s2, n)
end

---
-- Write pack all position information to the nodes of each snapshot
-- such that all nodes with the same supervertex have the same position
--
-- @param ugraph An undirected graph for which the vertices should get
-- their positions from the supergraph.
--
function Supergraph:sharePositions(ugraph, ignore)

  for _,vertex in ipairs(ugraph.vertices) do
    if not ignore then
      vertex.pos.x = self.supervertices[vertex].pos.x
      vertex.pos.y = self.supervertices[vertex].pos.y
    else
      if not ignore.x then
        vertex.pos.x = self.supervertices[vertex].pos.x
      end
      if not ignore.y then
        vertex.pos.y = self.supervertices[vertex].pos.y
      end
    end


  end
end

function Supergraph:onAllSnapshotvertices(f, ugraph)
  for _,vertex in ipairs(ugraph.vertices) do
    local snapshot_vertex = self.supertvertices[vertex]
    if snapshot_vertex then
      f(vertex, snapshot_vertex)
    end
  end
end

---
-- Split a supervertex into new supervertices such that
-- for a given snapshot there is a new pseudo-supervertex.
-- This pseudo-supervertex will be assigned to all snapshots
-- after the given snapshot.
-- All snapshots of a new pseudo-supervertex are removed from
-- the original vertex.
-- If a supervertex has no subvertices then it will not be added to the graph.
--
-- @param supervertex The supervertex which should be split.
--
-- @param snapshots An array of snapshots at which the supervertex
-- should be split into a new one with the corresponding pgf-vertices.
-- If there are more than one snapshots passed to the function
-- for each snapshot there will be a new pseudo-vertex
--
function Supergraph:splitSupervertex(supervertex, snapshots)
  assert(supervertex, "no supervertex defined")
  -- snapshots in temporal order
  table.sort(snapshots,
    function(s1,s2)
      return s1.timestamp < s2.timestamp
  end )

  assert(#snapshots~=0)

  local edit_snapshots = supervertex.snapshots
  local first_removed  = math.huge
  local rem_arcs = {}
  for i = 1, #snapshots do
    local s_first = self.snapshots_indices[snapshots[i]]
    first_removed = math.min(s_first,first_removed)
    local s_last
    if i==#snapshots then
      s_last = #self.snapshots
    else
      s_last = self.snapshots_indices[snapshots[i+1]]-1
    end

    local pseudovertex = Vertex.new {
      kind = "super",
      name = supervertex.name.."*"..i,
      subvertex = {},
      snapshots = {}
    }

    local has_subvertices = false

    for j = s_first, s_last do
      local s = self.snapshots[j]
      local vertex = self:getSnapshotVertex(supervertex, s)
      if vertex then
        self.supervertices[vertex] = pseudovertex
        self:addSnapshotVertex(pseudovertex, s, vertex)
        self:removeSnapshotVertex(supervertex, s)

        if not has_subvertices then
          has_subvertices = true
          self:add{pseudovertex}
        end

        -- update edges:
        local incoming = self.digraph:incoming(vertex)
        local outgoing = self.digraph:outgoing(vertex)

        for _, arc in ipairs(incoming) do
          local tail = self.supervertices[arc.tail]
          local head = self.supervertices[arc.head]
          self:assignToSuperarc(tail, pseudovertex, s)

          local super_arc = self:arc(tail, supervertex)
          if not rem_arcs[super_arc] then
            table.insert(rem_arcs, {arc = super_arc, snapshot = s})
            rem_arcs[super_arc] = true
          end
        end

        for _, arc in ipairs(outgoing) do
          local tail = self.supervertices[arc.tail]
          local head = self.supervertices[arc.head]
          self:assignToSuperarc(pseudovertex, head, s)

          local super_arc = self:arc(supervertex, head)
          if not rem_arcs[super_arc] then
            table.insert(rem_arcs, {arc = super_arc, snapshot = s})
            rem_arcs[super_arc] = true
          end
        end
      end
    end
  end

  if first_removed ~= math.huge then
    for _, removed_arc in ipairs(rem_arcs) do
      local snapshots = self.arc_snapshots[removed_arc.arc]
      for i=#snapshots,1,-1 do
        local s = snapshots[i]
        if s.timestamp >= removed_arc.snapshot.timestamp then
          table.remove(snapshots, i)
        end
      end

      if #snapshots==0 then
        self:disconnect(removed_arc.arc.tail, removed_arc.arc.head)
      end
    end
  end
end

-- function Supergraph:reloadArcSnapshots()
--   for _, arc in ipairs(self.digraph.arcs) do
--     local snapshot = self:getSnapshot(arc.head)
--     local superarc = self:getSuperarc(arc)
--     texio.write("\n"..arc.tail.name..">"..arc.head.name)
--     self.arc_snapshots[superarc] = snapshot
--   end
-- end

---
-- Remove the binding of a vertex at a certain snapshot from its assigned
-- supervertex.
-- This requires time $O(n)$ where $n$ is the number of nodes actually
-- assigned to the supervertex.
function Supergraph:removeSnapshotVertex(supervertex, snapshot)
  assert(supervertex and snapshot,"missing argument: the supervertex and snapshot must not be nil")

  -- remove reference to snapshot
  for i = #supervertex.snapshots,1,-1 do
    if supervertex.snapshots[i] == snapshot then
      table.remove(supervertex.snapshots, i)
      end
  end
  -- remove vertex at snapshot
  supervertex.subvertex[snapshot] = nil
end

---
-- Assign  a vertex to a snapshot vertex of this supergraph.
-- This requires time $O(1)$
-- @param supervertex
--
-- @param snapshot
--
-- @param vertex The vertex which should be assigned to the supervertex
-- for the given snapshot.
--
function Supergraph:addSnapshotVertex(supervertex, snapshot, vertex)
  supervertex.subvertex[snapshot] = vertex
  table.insert(supervertex.snapshots, snapshot)
end

---
-- Assign a given snapshot to the superarc between two supernodes.
-- If still no arc between those nodes exists a new edges will
-- be created.
-- This requires time $O(n)$ where $n$ is the number of snapshots already
-- assigned to the given arc.
--
-- @param super_tail The tail of the directed arc in the supergraph.
--
-- @param super_head The head of the directed arc in the supergraph.
--
-- @param snapshot A snapshot in which both nodes are connected.
--
-- @return The arc which was created or updated.
--
function Supergraph:assignToSuperarc(super_tail, super_head, snapshot)
  assert(self:contains(super_tail) and self:contains(super_head),
      "tried to connect supernodes not in the supergraph")

  local super_arc = self:arc(super_tail, super_head)
  if not super_arc then
    super_arc = self:connect(super_tail, super_head)
  end

  table.insert(self.arc_snapshots[super_arc], snapshot)
  self.arc_snapshots[super_arc][snapshot] = true

  return super_arc
end

return Supergraph

