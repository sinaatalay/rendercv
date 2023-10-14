-- Copyright 2013 by Sarah Mäusle and Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$



local BalancedNearestNeighbourInterchange = {}


-- Namespace
require("pgf.gd.phylogenetics").BalancedNearestNeighbourInterchange = BalancedNearestNeighbourInterchange

-- Imports
local InterfaceToAlgorithms = require("pgf.gd.interface.InterfaceToAlgorithms")
local DistanceMatrix        = require("pgf.gd.phylogenetics.DistanceMatrix")
local lib                   = require("pgf.gd.lib")

-- Shorthand:
local declare = InterfaceToAlgorithms.declare


---
declare {
  key = "balanced nearest neighbour interchange",
  algorithm = BalancedNearestNeighbourInterchange,
  phase = "phylogenetic tree optimization",
  phase_default = true,

  summary = [["
    The BNNI (Balanced Nearest Neighbor Interchange) is a
    postprocessing algorithm for phylogenetic trees. It swaps two
    distant 3-subtrees if the total tree length is reduced by doing
    so, until no such swaps are left.
  "]],
  documentation = [["
    This algorithm is from Desper and Gascuel, \emph{Fast and
    Accurate Phylogeny Reconstruction Algorithms Based on the
    Minimum-Evolution Principle}, 2002.
  "]]
}


---
declare {
  key = "no phylogenetic tree optimization",
  algorithm = { run = function(self) end },
  phase = "phylogenetic tree optimization",

  summary = [["
    Switches off any phylogenetic tree optimization.
  "]],
}



-- creates a binary heap, implementation as an array as described in
-- the respective wikipedia article
local function new_heap()
  local heap = {}

  function heap:insert(element, value)
    local object = { element = element, value = value }
    heap[#heap+1]= object

    local i = #heap
    local parent = math.floor(i/2)

    -- sort the new object into its correct place
    while heap[parent] and heap[parent].value < heap[i].value do
      heap[i] = heap[parent]
      heap[parent] = object
      i = parent
      parent = math.floor(i/2)
    end
  end

  -- deletes the top element from the heap
  function heap:remove_top_element()
    -- replace first element with last and delete the last element
    local element = heap[1].element
    heap[1] = heap[#heap]
    heap[#heap] = nil

    local i = 1
    local left_child = 2*i
    local right_child = 2*i +1

    -- sort the new top element into its correct place by swapping it
    -- against its largest child
    while heap[left_child] do
      local largest_child = left_child
      if heap[right_child] and heap[left_child].value < heap[right_child].value then
        largest_child = right_child
      end

      if heap[largest_child].value > heap[i].value then
        heap[largest_child], heap[i] = heap[i], heap[largest_child]
        i = largest_child
        left_child = 2*i
        right_child = 2*i +1
      else
        return element
      end
    end
    return element
  end

  return heap
end


-- BNNI (Balanced Nearest Neighbor Interchange)
--  [DESPER and GASCUEL: Fast and Accurate Phylogeny Reconstruction Algorithms Based on the Minimum-Evolution Principle, 2002]
-- swaps two distant-3 subtrees if the total tree length is reduced by doing so, until no such swaps are left
--
-- step 1: precomputation of all average distances between non-intersecting subtrees (already done by BME)
-- step 2: create heap of possible swaps
-- step 3: ( current tree with subtrees a,b,c,d: a--v-- {b, w -- {c, d}} )
--           (a): edge (v,w) is the best swap on the heap. Remove (v,c) and (w,b)
--           (b), (c), (d) : update the distance matrix
--           (e): remove the edge (v,w) from the heap; check the four edges adjacent to it for new possible swaps
--           (d): if the heap is non-empty, return to (a)

function BalancedNearestNeighbourInterchange:run()
  local g = self.tree
  -- create a heap of possible swaps
  local possible_swaps = new_heap()
  -- go over all arcs, look for possible swaps and add them to the heap [step 2]
  for _, arc in ipairs (g.arcs) do
    self:getBestSwap(arc, possible_swaps)
  end

  -- achieve best swap and update the distance matrix, until there is
  -- no more swap to perform

  while #possible_swaps > 0 do
    -- get the best swap and delete it from the heap
    local swap = possible_swaps:remove_top_element() --[part of step 3 (a)]

    -- Check if the indicated swap is still possible. Another swap may
    -- have interfered.
    if g:arc(swap.v, swap.subtree1) and g:arc(swap.w, swap.subtree2) and g:arc(swap.v, swap.w) and g:arc(swap.a, swap.v) and g:arc(swap.d, swap.w) then
      -- insert new arcs and delete the old ones to perform the swap [part of step 3 (a)]

      -- disconnect old arcs
      g:disconnect(swap.v, swap.subtree1)
      g:disconnect(swap.subtree1, swap.v)
      g:disconnect(swap.w, swap.subtree2)
      g:disconnect(swap.subtree2, swap.w)

      -- connect new arcs
      g:connect(swap.v, swap.subtree2)
      g:connect(swap.subtree2, swap.v)
      g:connect(swap.w, swap.subtree1)
      g:connect(swap.subtree1, swap.w)

      --update distance matrix
      self:updateBNNI(swap)

      -- update heap: check neighboring arcs for new possible swaps
      -- [step 3 (e)]
      self:getBestSwap(g:arc(swap.a,swap.v), possible_swaps)
      self:getBestSwap(g:arc(swap.subtree2, swap.v), possible_swaps)
      self:getBestSwap(g:arc(swap.d,swap.w), possible_swaps)
      self:getBestSwap(g:arc(swap.subtree1, swap.w), possible_swaps)
    end
  end

end


--
-- Gets the distance between two nodes as specified in the distances
-- fields. Note: this function assumes that the distance from a to b
-- is the
-- same as the distance from b to a.
--
-- @param a,b The nodes
-- @return The distance between the two nodes
function BalancedNearestNeighbourInterchange:distance(a, b)
  if a == b then
    return 0
  else
    local distances = self.distances
    return distances[a][b] or distances[b][a]
  end
end

-- updates the distance matrix after a swap has been performed [step3(b),(c),(d)]
--
-- @param swap A table containing the information on the performed swap
--             subtree1, subtree2: the two subtrees, which
--             were swapped
--             a, d: The other two subtrees bordering the
--             swapping edge
--             v, w : the two nodes connecting the swapping edge

function BalancedNearestNeighbourInterchange:updateBNNI(swap)
  local g = self.tree
  local b = swap.subtree1
  local c = swap.subtree2
  local a = swap.a
  local d = swap.d
  local v = swap.v
  local w = swap.w
  local distances = self.distances

  -- updates the distances in one of the four subtrees adjacent to the
  -- swapping edge
  function update_BNNI_subtree(swap, values)
    local g = self.tree
    local b = swap.farther
    local c = swap.nearer
    local a = swap.subtree
    local v = swap.v
    local d = swap.same
    local w = swap.w

    if not values then
      values = {
        visited = {[v] = v},
        possible_ys = {v},
        x = a,
        y = v
      }
      -- if we're looking at subtrees in one of the swapped subtrees,
      -- then need the old root (w) for the calculations
      if swap.swapped_branch then values.possible_ys = {w} end
    end
    local visited = values.visited
    local x = values.x
    local y = values.y
    local ys = values.possible_ys
    local l = 0 -- number of edges between y and v

    local dist_x_b = self:distance(x,b)
    local dist_x_c = self:distance(x,c)
    visited[x] = x --mark current x as visited

    -- loop over possible y's:
    for _, y in ipairs (ys) do
      -- update distance [step 3(b)]
      local distance = self:distance(x,y) - 2^(-l-2)*dist_x_b + 2^(-l-2)*dist_x_c

      if y == w then y = v end -- the old distance w,x was used for the new distance calculation, but it needs to be
      -- saved under its appropriate new name according to its new root. this case only arises when looking at x's
      -- in one of the swapped subtrees (b or c)

      distances[x][y] = distance
      distances[y][x] = distance
      l = l+1 -- length + 1, as the next y will be further away from v
    end

    -- update the distance between x and w (root of subtree c and d)
    -- [step 3(c)]
    local distance = 1/2 * (self:distance(x,b) + self:distance(x,d))
    distances[x][w] = distance
    distances[w][x] = distance

    -- go to next possible x's
    table.insert(ys, x) -- when we're at the next possible x, y can also be the current x
    for _,arc in ipairs (g:outgoing(x)) do
      if not visited[arc.head] then
        values.x = arc.head
        --go deeper
        update_BNNI_subtree(swap, values)
      end
    end
  end

  -- name the nodes/subtrees in a general way that allows the use of the function update_BNNI_subtree
  local update_a = {subtree = a, farther = b, nearer = c, v = v, same = d, w = w}
  local update_b = {subtree = b, farther = a, nearer = d, v = w, same = c, w = v, swapped_branch = true}
  local update_c = {subtree = c, farther = d, nearer = a, v = v, same = b, w = w, swapped_branch = true}
  local update_d = {subtree = d, farther = c, nearer = b, v = w, same = a, w = v}

  -- update the distances within the subtrees a,b,c,d respectively
  update_BNNI_subtree(update_a)
  update_BNNI_subtree(update_b)
  update_BNNI_subtree(update_c)
  update_BNNI_subtree(update_d)

  -- update the distance between subtrees v and w [step 3 (d)]:
  local distance = 1/4*( self:distance(a,b) + self:distance(a,d) + self:distance(c,b) + self:distance(c,d) )
  distances[v][w] = distance
  distances[w][v] = distance
end



-- finds the best swap across an arc and inserts it into the heap of
--  possible swaps
--
--  @param arc The arc, which is to be checked for possible swaps
--  @param heap_of_swaps The heap, containing all swaps, which
--  improve the total tree length
--
--  the following data of the swap are saved:
--    v,w = the nodes connecting the arc, across which the swap is
--          performed
--    subtree1,2 = the roots of the subtrees that are to be swapped
--    a,d = the roots of the two remaining subtrees adjacent to the arc

function BalancedNearestNeighbourInterchange:getBestSwap(arc, heap_of_swaps)
  local g = self.tree
  local possible_swaps = heap_of_swaps
  local v = arc.tail
  local w = arc.head
  local is_leaf = self.is_leaf

  -- only look at inner edges:
  if not is_leaf[v] and not is_leaf[w] then
    -- get the roots of the adjacent subtrees
    local a, b, c, d
    for _,outgoing in ipairs (g:outgoing(v)) do
      local head = outgoing.head
      if head ~= w then
        a = a or head
        b = head
      end
    end

    for _,outgoing in ipairs (g:outgoing(w)) do
      local head = outgoing.head
      if head ~= v then
        c = c or head
        d = head
      end
    end

    -- get the distances between the four subtrees
    local a_b = self:distance(a,b)
    local a_c = self:distance(a,c)
    local a_d = self:distance(a,d)
    local b_c = self:distance(b,c)
    local b_d = self:distance(b,d)
    local c_d = self:distance(c,d)

    -- difference in total tree length between old tree (T) and new tree (T')
    -- when nodes b and c are swapped
    local swap1 = 1/4*(a_b + c_d - a_c - b_d )

    -- difference in total tree length between old tree and new tree when nodes b and d are swapped
    local swap2 = 1/4*(a_b + c_d - a_d - b_c)

    -- choose the best swap that reduces the total tree length most (T-T' > 0)
    if swap1 > swap2 and swap1 > 0 then
    -- v,w = the nodes connecting the edge across which the swap is performed
    -- subtree1 = one of the nodes to be swapped; connected to v
    -- subtree2 = the other node to be swapped; connected to w
    -- a = other node connected to v
    -- d = other node connected to w
       local swap = { v = v, w = w, subtree1 = b, subtree2 = c, a = a, d = d }
      -- insert the swap into the heap
      possible_swaps:insert(swap, swap1)
    elseif swap2 > 0 then
      local swap = { v = v, w = w, subtree1 = b, subtree2 = d, d = c, a = a }
      possible_swaps:insert(swap, swap2)
    end
  end
end



return BalancedNearestNeighbourInterchange
