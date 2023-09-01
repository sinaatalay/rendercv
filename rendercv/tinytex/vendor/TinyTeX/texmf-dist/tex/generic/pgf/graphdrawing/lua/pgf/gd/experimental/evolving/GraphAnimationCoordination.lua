-- Copyright 2015 by Malte Skambath
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--
--
-- @field.visible_objects An array which stores for each supernode a mapping
--          of snapshots to the related visible snapshot nodes.
--          Note that these mappings may differ from the supergraph
--          because if there are two snapshot nodes in consecutive snapshots
--          then the first can be shown for a longer time period to
--          put aside some fade animations.
-- @field is_first A table storing for each snapshot node or snapshot arc if it
--          appears in its snapshot. This means that in the previous snapshot
--          there is no corresponding arc or node.
-- @field is_last A table storing for each snapshot node or arc if there
--          is no representative in the next snapshot.
-- @field move_on_enter A table which stores for each snapshot object if it is in
--                      motion while it appears in its snapshot.
-- @field move_on_leave A table which stores for each snapshot object if it is in
--                      motion while switching to the next snapshot
-- @field last_rep
--   A table which stores for every snapshot node if the representing (visible) node
--   disappears with the next snapshot.
--
-- @field previous_node The same as |next_node| just for the previous node
-- @field next_node A Storage to map each snapshot node to the next node in the
--                  following snapshot related to the same supernode.
--                  If in the next snapshot there is node following snapshot node
--                  then the value is nil.
--
local GraphAnimationCoordination = {}

-- Imports
local lib        = require "pgf.gd.lib"
local declare    = require("pgf.gd.interface.InterfaceToAlgorithms").declare
local Storage    = require "pgf.gd.lib.Storage"
local Coordinate = require "pgf.gd.model.Coordinate"


declare {
  key           = "modified",
  type          = "boolean",
  Initial       = false,
  documentation = [["
    This key specifies, if a supernode changed its
    visual properties since the last snapshot.
    The default value is |false| and prevent the algorithm
    to produce a lot of unnecessary animations.
  "]]
}

declare {
  key  = "unmodified",
  use = {
    { key = "modified", boolean = false},
  },
}


---
declare {
  key     = "minimum rest time",
  type    = "number",
  initial = 0.5,
  documentation = [["
    This key specifies a minimum time in which a single node
    has to be prohibited to be animated.
    For a node with minimum rest time of 1s that exists in a snapshot
    at time $t$ this means that all animations including movements and fadings
    are only allowed before $t$-0.5s and after $t$+0.5s.
  "]],
}

declare {
  key     = "maximum motion time",
  type    = "number",
  initial = math.huge,
  documentation = [["
    Use this key if you want to limit the time during nodes are allowed to move
    when they changing their positions.
  "]],
}

declare {
  key     = "overlapping transition",
  type    = "boolean",
  initial = true,
  documentation = [["
    Use this key if you want to allow that the fade animations for or
    disappearing nodes may occurs while the mid time between two snapshots.
    If false then the appearing ends on the midtime and the disappearing
    starts in this moment.
  "]]
}

---
declare {
  key = "default evolving graph animation",
  algorithm = GraphAnimationCoordination,
  phase = "evolving graph animation",
  phase_default = true,
  summary = [["
      This phase animates all vertices including movements and
      fade in or fade out animations given an evolving graph as sequence
      of single snapshot graphs.
  "]],
  documentation = [["
    This phase animates all vertices including movements and
    fade in or fade out animations given an evolving graph as sequence
    of single snapshot graphs.

    Your algorithm needs to work on evolving graphs and has to use
    the |evolving graph animation| phase. You do not need to use
    this key by yourself then because this key starts the default
    algorithm algorithm of the phase.
    %
    \begin{codeexample}[]
     local ga_class = self.digraph.options.algorithm_phases['evolving graph animation']
     -- animate graph
     ga_class.new {
       main_algorithm = self,
       supergraph     = supergraph,
       digraph        = self.digraph,
       ugraph         = self.ugraph
     }:run()
     \end{codeexample}

    This algorithm and phase require a supergraph instance and the original
    digraph and ugraph. Note that you have to set the layout of the snapshot
    nodes before running algorithms of this is useful.
  "]],
}

-- Help functions

--
-- Appends a move animation to a given snapshot object such that the
-- object moves from one point to another on a straight line.  Note
-- that the coordinates of the two points are given as relative
-- coordinates to the current origin of the object.
--
-- This means if we want to move a node 1cm to the right the value of
-- |c_from| has to be (0,0) while |c_to| must be (1,0).  The argument
-- |c_from| is useful for a node which has a position but its
-- previous node related to the same supervertex is at a different
-- position.  Then we can use this argument to move the new node to
-- its origin position for smooth transitions.
--
-- @field object   The snapshot object which should be moved
--
-- @field c_from   The coordinate where the animation starts
--
-- @field c_to     The coordinate where the animation should end
--
-- @field t_start   The time when the movement starts.
--
-- @field t_end     The time when the animation stops.
local function append_move_animation(object, c_from, c_to, t_start, t_end)
  if not object then return end
  assert(object, "no object to animate")
  if ((c_from.x~=c_to.x) or (c_from.y~=c_to.y))then
    local animations = object.animations or {}
    local c1 = Coordinate.new((2*c_from.x+c_to.x)/3,(2*c_from.y+c_to.y)/3)
    local c2 = Coordinate.new((c_from.x+2*c_to.x)/3,(c_from.y+2*c_to.y)/3)
    local t1 = (7*t_start + 5*t_end)/12
    local t2 = (5*t_start + 7*t_end)/12
    table.insert(animations, {
           attribute = "translate",
           entries = {
             { t = t_start, value = c_from},
--             { t = t1,      value = c1 },
--             { t = t2,      value = c2 },
             { t = t_end,   value = c_to }
           },
           options = { { key = "freeze at end",   },
--             {key = "entry control", value="0}{1",}
           }
    })
    object.animations = animations
  end
end

local function append_fade_animation(object, v_start, v_end, t_start, t_end)
  local animations = object.animations or {}

  if v_start == 0 then
    table.insert(animations, {
           attribute = "stage",
           entries = { { t = t_start, value = "true"}, },
           options = { { key = "freeze at end" } }
    })
  elseif v_end == 0 and nil  then
    table.insert(animations, {
           attribute = "stage",
           entries = { { t = t_end, value = "false"}, },
           options = { --{ key = "freeze at end" }
           }
    })
  end

  table.insert(animations, {
    attribute = "opacity",
    entries = {
      {    t = t_start, value = v_start },
      { t = t_end,   value = v_end } },
    options = { { key = "freeze at end" } }
  })
  object.animations = animations
end

--
-- check if the difference/vector between two pairs (a1,a2),(b1,b2) of points
-- is the same.
local function eq_offset(a1, a2, b1, b2)
  local dx = ((a1.x-a2.x) - (b1.x-b2.x))
  local dy = ((a1.y-a2.y) - (b1.y-b2.y))
  if dx<0 then dx = -dx end
  if dy<0 then dy = -dy end
  return dx<0.001 and dy<0.001
end

--
-- Check if two arcs connect a pair of nodes at the same position.
-- This can be used as an indicator that two consecutive arcs
-- can be represented by the same arc object.
--
local function eq_arc(arc1, arc2)
  if not arc1 or not arc2 then
    return false
  end
  return eq_offset(arc1.tail.pos, arc1.head.pos, arc2.tail.pos, arc2.head.pos)
end


-- Implementation

function GraphAnimationCoordination:run()
  assert(self.supergraph, "no supergraph defined")

  self.is_first        = Storage.new()
  self.is_last         = Storage.new()
  self.last_rep        = Storage.new()
  self.move_on_enter   = Storage.new()
  self.move_on_leave   = Storage.new()
  self.previous_node   = Storage.new()
  self.next_node       = Storage.new()
  self.visible_objects = Storage.new()


  self:precomputeNodes()
  self:precomputeEdges()
  self:animateNodeAppearing()
  self:animateEdgeAppearing()
  self:generateNodeMotions()
  self:generateEdgeMotions()
end

function GraphAnimationCoordination:generateNodeMotions(node_types)
  local supergraph = self.supergraph
  local graph = self.digraph

  for _, supervertex in ipairs(self.supergraph.vertices) do
    local lj = -1
    local last_v    = nil
    local last_time = nil
    for j, s in ipairs(supergraph.snapshots) do
      local vertex = supergraph:getSnapshotVertex(supervertex, s)

      if lj == j-1 and vertex and last_v then
    local mrt1 = last_v.options["minimum rest time"]/2
    local mrt2 = vertex.options["minimum rest time"]/2

        local s1 = Coordinate.new(0,0)
    local e1 = Coordinate.new(vertex.pos.x-last_v.pos.x,-vertex.pos.y+last_v.pos.y)

    local s2 = Coordinate.new(-vertex.pos.x+last_v.pos.x,vertex.pos.y-last_v.pos.y)
    local e2 = Coordinate.new(0,0)

    local t_end   = s.timestamp - math.max(0, mrt2)
    local t_start = last_time + math.max(0,mrt1)

    local representative =  self.visible_objects[supervertex][s]
    if representative == vertex then
      append_move_animation(vertex,  s2, e2, t_start, t_end)
      append_move_animation(last_v, s1, e1, t_start, t_end)
    else
      append_move_animation(representative,s1,e1,t_start,t_end)
    end
      end
      last_time = s.timestamp
      lj = j
      last_v = vertex
    end
  end
end





function GraphAnimationCoordination:generateEdgeMotions()
  local supergraph = self.supergraph
  local graph = self.digraph

  for i, arc in ipairs(supergraph.arcs) do
    local head = arc.head
    local tail = arc.tail

    local last_arc  = nil
    local last_time = nil
    local last_v = nil
    local last_w = nil

    for j, s in ipairs(supergraph.snapshots) do
      local v = supergraph:getSnapshotVertex(tail,s)
      local w = supergraph:getSnapshotVertex(head,s)

      if v and w then
    local this_arc = graph:arc(v,w) --or graph:arc(w,v)
        if this_arc then
      if this_arc and last_arc then
        local mrt1 = last_v.options["minimum rest time"]/2
        local mrt2 = v.options["minimum rest time"]/2

        local s1 = Coordinate.new(0,0)--lv.pos
        local e1 = Coordinate.new(v.pos.x-last_v.pos.x,-v.pos.y+last_v.pos.y)

        local s2 = Coordinate.new(-v.pos.x+last_v.pos.x,v.pos.y-last_v.pos.y)
        local e2 = Coordinate.new(0,0)

        local t_end     = s.timestamp - math.max(0,mrt2)
        local t_start   = last_time   + math.max(0,mrt1)

        local representative = self.visible_objects[arc][s]
        if representative == this_arc then
          append_move_animation(last_arc, s1, e1, t_start,t_end)
          append_move_animation(this_arc, s2, e2, t_start,t_end)
        else
          append_move_animation(representative,s1,e1,t_start,t_end)
        end
        this_arc = representative
      end
      last_arc = this_arc
      last_v = v
      last_time = s.timestamp
    else
      last_arc = nil
    end
      else
    last_arc = nil
      end
    end
  end
end

--
--
-- @field t_transition  The mid time between two snapshot times.
-- @field fade_duration The duration of the fade animation
-- @field overlapping   A boolean defining if the animation occurs
--                      before and after the mid time (true) or if it
--                      starts/end only in one interval (false)
-- @field closing       A boolean specifying if this is an outfading time
local function compute_fade_times(t_transition, fade_duration, overlapping, closing)

  if overlapping then
    t_start = t_transition - fade_duration / 2
    t_end   = t_transition + fade_duration / 2
  else
    if closing then
      t_start = t_transition - fade_duration
      t_end   = t_transition
    else
      t_start = t_transition
      t_end   = t_transition + fade_duration
    end
  end
  return {t_start = t_start, t_end = t_end}
end

function GraphAnimationCoordination:animateNodeAppearing()
  local supergraph = self.supergraph
  for i,vertex in ipairs(self.ugraph.vertices) do
    local snapshot = supergraph:getSnapshot(vertex)
    local interval = snapshot.interval
    local supernode = supergraph:getSupervertex(vertex)
    local representative =  self.visible_objects[supernode][snapshot]
    local overlapping_in = true -- init true for crossfading
    local overlapping_out= true
    local minimum_rest_time = math.max(0,vertex.options["minimum rest time"])
    local allow_overlapping = vertex.options["overlapping transition"]
    local fadein_duration = 0.01
    local fadeout_duration = 0.01

    if self.is_first[vertex] then
      fadein_duration = self.ugraph.options["fadein time"]
      overlapping_in = false or allow_overlapping
    end
    if self.is_last[vertex] then
      fadeout_duration = self.ugraph.options["fadeout time"]
      overlapping_out = false or allow_overlapping
    end

    if fadein_duration == math.huge or fadein_duration<0 then
      fadein_duration = (interval.to-interval.from-minimum_rest_time)/2
      if overlapping then fadein_duration = fadein_duration * 2 end
    end
    if fadeout_duration == math.huge or fadeout_duration<0 then
      fadeout_duration = (interval.to-interval.from-minimum_rest_time)/2
      if overlapping then fadeout_duration = fadeout_duration*2 end
    end

    local fin = compute_fade_times(interval.from, fadein_duration, overlapping_in, false)
    local fout = compute_fade_times(interval.to, fadeout_duration, overlapping_out, true)

    vertex.animations    =  vertex.animations or {}

    if representative~= vertex then
      table.insert(vertex.animations,{
             attribute = "stage",
             entries = { { t = 0, value = "false"}, },
             options = {}
      })
    end

    if interval.from > -math.huge and (vertex == representative or self.is_first[vertex]) then
      -- only appears if the snapshot node is its own repr. or if in the prev snapshot is
      -- no representative.
      append_fade_animation(representative, 0, 1, fin.t_start, fin.t_end)
    end
    if interval.to < math.huge and (self.is_last[vertex] or self.last_rep[vertex]) then
      -- The snapshot node only disappears when the node is not visible
      -- in the next or (this=)last  snapshot:
      append_fade_animation(representative, 1, 0, fout.t_start, fout.t_end)
    end
  end
end



function GraphAnimationCoordination:animateEdgeAppearing()
  local supergraph = self.supergraph
  local graph = self.digraph
  for _,edge in ipairs(graph.arcs) do
    local snapshot = supergraph:getSnapshot(edge.head)
    local int = snapshot.interval
    local superarc = supergraph:getSuperarc(edge)
    local representative = self.visible_objects[superarc][snapshot] or edge

    local minimum_rest_time = math.max(0,edge.head.options["minimum rest time"]/2,
        edge.tail.options["minimum rest time"]/2)

    local appears    = math.max(int.from, int.from)
    local disappears = math.min(int.to,   int.to)

    local overlapping_in = true -- init true for crossfading
    local overlapping_out= true
    local fadein_duration = 0.01
    local fadeout_duration = 0.01
    local allow_overlapping = (edge.tail.options["overlapping transition"] and edge.head.options["overlapping transition"])

    if self.is_first[edge] and not self.move_on_enter[edge] and not self.move_on_enter[edge.head] then
      fadein_duration = self.ugraph.options["fadein time"]
      overlapping_in = false or allow_overlapping
    end

    if self.is_last[edge] and not self.move_on_leave[edge]  then
      fadeout_duration = self.ugraph.options["fadeout time"]
      overlapping_out = false or allow_overlapping
    end


    if self.is_first[edge]
        and (self.move_on_enter[edge.head]
        or self.move_on_enter[edge.tail] )
    then
      appears = snapshot.timestamp - minimum_rest_time
    end
    if self.is_last[edge] and
        (self.move_on_leave[edge.head]
         or self.move_on_leave[edge.tail]
        ) then
      disappears = snapshot.timestamp + minimum_rest_time
    end

    local fin = compute_fade_times(appears, fadein_duration, overlapping_in,false)
    local fout = compute_fade_times(disappears,fadeout_duration,overlapping_out,true)

    edge.animations = edge.animations or {}

    if representative~=edge then
      table.insert(edge.animations,{
                   attribute = "stage",
                   entries = { { t = 0, value = "false"}, },
                   options = {}})
    end

    -- Fade in:
    if appears > -math.huge and (edge == representative or self.is_first[edge]) then
      append_fade_animation(representative, 0, 1, fin.t_start, fin.t_end )
    end

    -- Fade out:
    if disappears < math.huge and (self.is_last[edge] or self.last_rep[edge])then
      append_fade_animation(representative, 1, 0, fout.t_start,fout.t_end )
    end
  end
end

function GraphAnimationCoordination:precomputeNodes()
  local supergraph = self.supergraph

  for _, supernode in ipairs(supergraph.vertices) do

    local vis_nodes = {}
    self.visible_objects[supernode] = vis_nodes

    local any_previous_node = nil
    local previous_representant = nil
    local node_before = nil

    for i, s in ipairs(supergraph.snapshots) do
      local node = supergraph:getSnapshotVertex(supernode, s)

      if node then
        -- assume the node is the last node
        self.is_last[node] = true

        if node.options["modified"] then
          -- modified
          vis_nodes[s] = node
          previous_representant = node
          if any_previous_node then
            self.last_rep[any_previous_node] = true
          end
        else
          -- unmodified
          previous_representant = previous_representant or node
          vis_nodes[s] = previous_representant
        end
        any_previous_node = node

        if node_before then
          self.is_last[node_before] = false
          self.previous_node[node]     = node_before
          self.next_node[node_before]  = node

          local do_move = (( node.pos.x ~= node_before.pos.x )
              or (node.pos.y ~= node_before.pos.y))
          self.move_on_enter[node]        = do_move
          self.move_on_leave[node_before] = do_move
        else
          self.is_first[node] = true
        end
        node_before = node
      else
        node_before = nil
      end
    end
  end
end

function GraphAnimationCoordination:precomputeEdges()
  -- 1. classify arcs (appearing, disappearing)
  for _, arc in ipairs(self.digraph.arcs) do
    local head = arc.head
    local tail = arc.tail
    if not ( self.is_first[head] or self.is_first[tail]) then
      if not self.digraph:arc(self.previous_node[tail], self.previous_node[head]) then
        -- new arc connects existing nodes
        self.is_first[arc] = true
      end
    else
      -- arc and at least one node is new.
      self.is_first[arc] = true
    end
    if not ( self.is_last[head] or self.is_last[tail]) then
      if not self.digraph:arc(self.next_node[tail],self.next_node[head]) then
        -- arc disappears while nodes are still in the next snapshot
        self.is_last[arc] = true
      end
    else
      -- arc and at least one node disappears in the next snapshot
      self.is_last[arc] = true
    end
    self.move_on_enter[arc] = self.move_on_enter[head] or self.move_on_enter[tail]
    self.move_on_leave[arc] = self.move_on_leave[head] or self.move_on_leave[tail]
  end

  -- 2. precompute the unmodified edges
  local supergraph = self.supergraph

  for _, superarc in ipairs(supergraph.arcs) do
    local vis_objects = {}
    self.visible_objects[superarc] = vis_objects

    local previous_arc
    local previous_representant

    for _, s in ipairs(supergraph.arc_snapshots[superarc]) do
      local head = supergraph:getSnapshotVertex(superarc.head, s)
      local tail = supergraph:getSnapshotVertex(superarc.tail,  s)
      -- use the digraph because the snapshot arc is not synced
      local arc = self.digraph:arc(tail, head)

      local modified = false
      local opt_array = arc:optionsArray('modified')
      for i = 1,#opt_array.aligned do
        modified = modified or opt_array[i]
      end

      if modified  or
      not eq_arc(arc, previous_arc) or self.is_first[arc] then
        --modified
        previous_representant = arc
        vis_objects[s] = arc
        if previous_arc then
          self.last_rep[previous_arc] = true
        end
       else
        -- unmodified
        previous_representant = previous_representant or arc
        vis_objects[s] = previous_representant
      end
      previous_arc = arc
    end
  end
end
-- Done

return GraphAnimationCoordination
