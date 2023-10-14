local E = {}

require("pgf.gd.planar").Embedding = E

-- includes
local LinkedList = require("pgf.gd.planar.LinkedList")

E.vertexmetatable = {
  __tostring = function(v)
    if v.name then
      return v.name
    elseif v.inputvertex then
      return v.inputvertex.name
    else
      return tostring(v)
    end
  end
}

E.halfedgemetatable = {
  __tostring = function(e)
    return tostring(e.twin.target)
      .. " -> "
      .. tostring(e.target)
  end
}

-- create class properties
E.__index = E

function E.new()
  local t = {
    vertices = {},
  }
  setmetatable(t, E)
  return t
end

function E:add_vertex(name, inputvertex, virtual)
  virtual = virtual or nil
  local vertex = {
    adjmat = {},
    name = name,
    inputvertex = inputvertex,
    virtual = virtual,
  }
  setmetatable(vertex, E.vertexmetatable)
  table.insert(self.vertices, vertex)
  return vertex
end

function E:add_edge(v1, v2, after1, after2, virtual)
  assert(v1.link == nil or v1 == after1.twin.target)
  assert(v2.link == nil or v2 == after2.twin.target)
  assert(v1.adjmat[v2] == nil)
  assert(v2.adjmat[v1] == nil)

  virtual = virtual or nil

  local halfedge1 = {
    target = v2,
    virtual = virtual,
    links = {},
  }
  local halfedge2 = {
    target = v1,
    virtual = virtual,
    links = {},
  }
  halfedge1.twin = halfedge2
  halfedge2.twin = halfedge1

  setmetatable(halfedge1, E.halfedgemetatable)
  setmetatable(halfedge2, E.halfedgemetatable)

  if v1.link == nil then
    v1.link = halfedge1
    halfedge1.links[0] = halfedge1
    halfedge1.links[1] = halfedge1
  else
    halfedge1.links[0] = after1.links[0]
    after1.links[0].links[1] = halfedge1
    halfedge1.links[1] = after1
    after1.links[0] = halfedge1
  end

  if v2.link == nil then
    v2.link = halfedge2
    halfedge2.links[0] = halfedge2
    halfedge2.links[1] = halfedge2
  else
    halfedge2.links[0] = after2.links[0]
    after2.links[0].links[1] = halfedge2
    halfedge2.links[1] = after2
    after2.links[0] = halfedge2
  end

  v1.adjmat[v2] = halfedge1
  v2.adjmat[v1] = halfedge2

  return halfedge1, halfedge2
end

function E:remove_virtual()
  local virtuals = {}
  for i, v in ipairs(self.vertices) do
    if v.virtual then
      table.insert(virtuals, i)
    else
      local start = v.link
      local current = start
      repeat
        current = current.links[0]
        if current.virtual then
          current.links[0].links[1] = current.links[1]
          current.links[1].links[0] = current.links[0]
          v.adjmat[current.target] = nil
          current.target.adjmat[v] = nil
        end
      until current == start
    end
  end
  for i = #virtuals, 1, -1 do
    self.vertices[virtuals[i]] = self.vertices[#self.vertices]
    table.remove(self.vertices)
  end
end 

-- for the use in for-loops
-- iterates over the adjacency list of a vertex
-- given a half edge to start and a direction (0 or 1, default 0)
function E.adjacency_iterator(halfedge, direction)
  direction = direction or 0
  local function next_edge(startedge, prevedge)
    if prevedge == nil then
      return startedge
    else
      local nextedge = prevedge.links[direction]
      if nextedge ~= startedge then
        return nextedge
      else
        return nil
      end
    end
  end
  return next_edge, halfedge, nil
end

function E.face_iterator(halfedge, direction)
  direction = direction or 0
  local function next_edge(startedge, prevedge)
    if prevedge == nil then
      return startedge
    else
      local nextedge = prevedge.twin.links[1 - direction]
      if nextedge ~= startedge then
        return nextedge
      else
        return nil
      end
    end
  end
  return next_edge, halfedge, nil
end

function E:triangulate()
  local visited = {}
  for _, vertex in ipairs(self.vertices) do
    for start in E.adjacency_iterator(vertex.link) do
      if not visited[start] then
        local prev = start
        local beforestart = start.links[0].twin
        local current = start.twin.links[1]
        local next = current.twin.links[1]
        visited[start] = true
        visited[current] = true
        visited[next] = true
        while next ~= beforestart do
          local halfedge1, halfedge2
          if vertex ~= current.target
              and not vertex.adjmat[current.target] then
            halfedge1, halfedge2 = self:add_edge(
              vertex, current.target,
              prev, next,
              true
            )

            prev = halfedge1
            current = next
            next = next.twin.links[1]
          elseif not prev.target.adjmat[next.target] then
            halfedge1, halfedge2 = self:add_edge(
              prev.target, next.target,
              current, next.twin.links[1],
              true
            )

            current = halfedge1
            next = halfedge2.links[1]
          else
            local helper = next.twin.links[1]
            halfedge1, halfedge2 = self:add_edge(
              current.target, helper.target,
              next, helper.twin.links[1],
              true
            )

            next = halfedge1
          end

          visited[next] = true
          visited[halfedge1] = true
          visited[halfedge2] = true
        end
      end
    end
  end
end

function E:canonical_order(v1, v2, vn)
  local n = #self.vertices
  local order = { v1 }
  local marks = { [v1] = "ordered", [v2] = 0 }
  local visited = {}
  local vk = v1
  local candidates = LinkedList.new()
  local listelements = {}
  for k = 1, n-2 do
    for halfedge in E.adjacency_iterator(vk.link) do
      local vertex = halfedge.target
      if vertex ~= vn then
        local twin = halfedge.twin
        visited[twin] = true
        if marks[vertex] == nil then
          marks[vertex] = "visited"
        elseif marks[vertex] ~= "ordered" then
          local neighbor1 = visited[twin.links[0]]
          local neighbor2 = visited[twin.links[1]]
          if marks[vertex] == "visited" then
            if neighbor1 or neighbor2 then
              marks[vertex] = 1
              listelements[vertex] = candidates:addback(vertex)
            else
              marks[vertex] = 2
            end
          else
            if neighbor1 == neighbor2 then
              if neighbor1 and neighbor2 then
                marks[vertex] = marks[vertex] - 1
              else
                marks[vertex] = marks[vertex] + 1
              end
              if marks[vertex] == 1 then
                listelements[vertex]
                    = candidates:addback(vertex)
              elseif listelements[vertex] then
                candidates:remove(listelements[vertex])
                listelements[vertex] = nil
              end
            end
          end
        end
      end
    end
    vk = candidates:popfirst()
    order[k+1] = vk
    marks[vk] = "ordered"
  end
  order[n] = vn
  return order
end

function E:get_biggest_face()
  local number = 0
  local edge
  local visited = {}
  for _, vertex in ipairs(self.vertices) do
    for start in E.adjacency_iterator(vertex.link) do
        local count = 0
        if not visited[start] then
          visited[start] = true
          local current = start
          repeat
            count = count + 1
            current = current.twin.links[1]
          until current == start
          if count > number then
            number = count
            edge = start
          end
        end
    end
  end
  return edge, number
end

function E:surround_by_triangle(faceedge, facesize)
  local divisor = 3
  if facesize > 3 then
    divisor = 4
  end
  local basenodes = math.floor(facesize / divisor)
  local extranodes = facesize % divisor
  local attachnodes = { basenodes, basenodes, basenodes }
  if facesize > 3 then
    attachnodes[2] = basenodes * 2
  end
  for i = 1,extranodes do
    attachnodes[i] = attachnodes[i] + 1
  end

  local v = {
    self:add_vertex("$v_1$", nil, true),
    self:add_vertex("$v_n$", nil, true),
    self:add_vertex("$v_2$", nil, true)
  }
  for i = 1,3 do
    local currentv = v[i]
    local nextv = v[i % 3 + 1]
    self:add_edge(currentv, nextv, currentv.link, nextv.link, true)
  end

  local current = faceedge
  local next = current.twin.links[1]
  for i = 1,3 do
    local vertex = v[i]
    local otheredge = vertex.adjmat[v[i % 3 + 1]]
    local previnserted = otheredge.links[1]
    for count = 1, attachnodes[i] do
      if not vertex.adjmat[current.target] then
        previnserted, _ = self:add_edge(
          vertex, current.target,
          previnserted, next,
          true
        )
      end

      current = next
      next = next.twin.links[1]
    end
    if not vertex.adjmat[current.target] then
      previnserted, _ = self:add_edge(
        vertex, current.target,
        previnserted, next,
        true
      )
      current = previnserted
    end
  end
  return v[1], v[3], v[2]
end

function E:improve()
  local pairdata = {}
  local inpair = {}
  for i, v1 in ipairs(self.vertices) do
    for j = i + 1, #self.vertices do
      local v2 = self.vertices[j]
      local pd = self:find_pair_components(v1, v2)
      if pd then
        inpair[v1] = true
        inpair[v2] = true
        table.insert(pairdata, pd)
      end
    end
    if not inpair[v1] then
      local pd = self:find_pair_components(v1, nil)
      if pd then
        inpair[v1] = true
        table.insert(pairdata, pd)
      end
    end
  end

  local changed
  local runs = 1
  local edgepositions = {}
  repeat
    changed = false
    for i, pd in ipairs(pairdata) do
      self:improve_separation_pair(pd)
    end
    -- check for changes
    for i, v in ipairs(self.vertices) do
      local start = v.link
      local current = start
      local counter = 1
      repeat
        if counter ~= edgepositions[current] then
          changed = true
          edgepositions[current] = counter
        end
        counter = counter + 1
        current = current.links[0]
      until current == start
    end
    runs = runs + 1
  until changed == false or runs > 100
end

function E:find_pair_components(v1, v2)
  local visited = {}
  local companchors = {}
  local edgecomps = {}
  local compvertices = {}
  local islinear = {}
  local edgeindices = {}

  local pair = { v1, v2 }
  local start = v1.link
  local current = start
  local edgeindex = 1
  -- start searches from v1
  repeat
    edgeindices[current] = edgeindex
    edgeindex = edgeindex + 1
    if not edgecomps[current] then
      local compindex = #companchors + 1
      local ca, il
      edgecomps[current] = compindex
      compvertices[compindex] = {}
      local target = current.target
      if target == v2 then
        edgecomps[current.twin] = compindex
        ca = 3
        il = true
      else
        ca, il = self:component_dfs(
            target,
            pair,
            visited,
            edgecomps,
            compvertices[compindex],
            compindex
        )
      end
      companchors[compindex] = ca
      islinear[compindex] = il
    end
    current = current.links[0]
  until current == start

  if v2 then
    start = v2.link
    current = start
    local lastincomp = true
    local edgeindex = 1
    -- now find the remaining blocks at v2
    repeat
      edgeindices[current] = edgeindex
      edgeindex = edgeindex + 1
      if not edgecomps[current] then
        local compindex = #companchors + 1
        edgecomps[current] = compindex
        compvertices[compindex] = {}
        self:component_dfs(
          current.target,
          pair,
          visited,
          edgecomps,
          compvertices[compindex],
          compindex
        )
        companchors[compindex] = 2
      end
      current = current.links[0]
    until current == start
  end

  -- init compedges, tricomps, twocomps
  local tricomps = {}
  local twocomps = {{}, {}}
  for i, anchors in ipairs(companchors) do
    if anchors == 3 then
      table.insert(tricomps, i)
    else
      table.insert(twocomps[anchors], i)
    end
  end

  local flipimmune = #tricomps == 2
      and (islinear[tricomps[1]] or islinear[tricomps[2]])
  if (#tricomps < 2 or flipimmune)
      and (v2 ~= nil or #twocomps[1] < 2) then
    return nil
  end

  -- order tri comps cyclic
  local function sorter(a, b)
      return #compvertices[a] < #compvertices[b]
  end

  table.sort(tricomps, sorter)

  -- determine order of comps
  local numtricomps = #tricomps
  local comporder = { {}, {} }
  local bottom = math.ceil(numtricomps / 2)
  local top = bottom + 1
  for i, comp in ipairs(tricomps) do
    if i % 2 == 1 then
      comporder[1][bottom] = comp
      comporder[2][numtricomps - bottom + 1] = comp
      bottom = bottom - 1
    else
      comporder[1][top] = comp
      comporder[2][numtricomps - top + 1] = comp
      top = top + 1
    end
  end

  local pairdata = {
    pair = pair,
    companchors = companchors,
    edgecomps = edgecomps,
    edgeindices = edgeindices,
    compvertices = compvertices,
    tricomps = tricomps,
    twocomps = twocomps,
    comporder = comporder,
  }
  return pairdata
end

function E:component_dfs(v, pair, visited, edgecomps, compvertices, compindex)
  visited[v] = true
  local start = v.link
  local current = start
  local companchors = 1
  local numedges = 0
  local islinear = true
  table.insert(compvertices, v)
  repeat
    numedges = numedges + 1
    local target = current.target
    if target == pair[1] or target == pair[2] then
      edgecomps[current.twin] = compindex
      if target == pair[2] then
        companchors = 3
      end
    elseif not visited[target] then
      local ca, il = self:component_dfs(
        target,
        pair,
        visited,
        edgecomps,
        compvertices,
        compindex
      )
      if ca == 3 then
        companchors = 3
      end
      islinear = islinear and il
    end
    current = current.links[0]
  until current == start
  return companchors, islinear and numedges == 2
end

function E:improve_separation_pair(pairdata)
  local pair = pairdata.pair
  local companchors = pairdata.companchors
  local edgecomps = pairdata.edgecomps
  local edgeindices = pairdata.edgeindices
  local compvertices = pairdata.compvertices
  local tricomps = pairdata.tricomps
  local twocomps = pairdata.twocomps
  local comporder = pairdata.comporder
  local v1 = pair[1]
  local v2 = pair[2]

  local compedges = {}
  for i = 1, #companchors do
      compedges[i] = {{}, {}}
  end

  local numtricomps = #tricomps
  local numtwocomps = { #twocomps[1], #twocomps[2] }

  -- find compedges
  for i = 1, #pair do
    -- first find an edge that is the first of a triconnected component
    local start2
    if v2 then
      start = pair[i].link
      current = start
      local last
      repeat
        local comp = edgecomps[current]
        if companchors[comp] == 3 then
          if last == nil then
            last = comp
          elseif last ~= comp then
            start2 = current
            break
          end
        end
        current = current.links[0]
      until current == start
    else
      start2 = pair[i].link
    end
    -- now list the edges by components
    current = start2
    repeat
      table.insert(compedges[edgecomps[current]][i], current)
      current = current.links[0]
    until current == start2
  end

  -- count edges on each side of tri comps
  local edgecount = {}
  for _, comp in ipairs(tricomps) do
    edgecount[comp] = {}
    for i = 1, #pair do
      local count = 1
      local current = compedges[comp][i][1]
      local other = pair[3 - i]
      while current.target ~= other do
        count = count + 1
        current = current.twin.links[0]
      end
      edgecount[comp][i] = count
    end
  end

  -- determine which comps have to be flipped
  local flips = {}
  local numflips = 0
  local allflipped = true
  for i, comp in ipairs(comporder[1]) do
    local side1, side2
    if i > numtricomps / 2 then
      side1 = edgecount[comp][1]
      side2 = edgecount[comp][2]
    else
      side1 = edgecount[comp][2]
      side2 = edgecount[comp][1]
    end
    if side1 > side2 then
      numflips = numflips + 1
      flips[comp] = true
    elseif side1 < side2 then
      allflipped = false
    end
  end

  if allflipped then
    for i, comp in ipairs(tricomps) do
      flips[comp] = false
    end
  else
    for i, comp in ipairs(tricomps) do
      if flips[comp] then
        for _, v in ipairs(compvertices[comp]) do
          local start = v.link
          local current = start
          repeat
            current.links[0], current.links[1]
                = current.links[1], current.links[0]
            current = current.links[1]
        until current == start
        end
      end
    end
  end

  -- order edges cyclic per component (one cycle for all tri comps)
  for i = 1, #pair do
    if v2 then
      local co
      if allflipped then
        co = comporder[3 - i]
      else
        co = comporder[i]
      end

      local id = co[numtricomps]
      lastedges = compedges[id][i]
      if flips[id] then
        lastedge = lastedges[1]
      else
        lastedge = lastedges[#lastedges]
      end

      -- tri comps
      for _, id in ipairs(co) do
        local edges = compedges[id][i]
        local from
        local to
        local step
        if flips[id] then
          from = #edges
          to = 1
          step = -1
        else
          from = 1
          to = #edges
          step = 1
        end
        for k = from, to, step do
          local edge = edges[k]
          lastedge.links[0] = edge
          edge.links[1] = lastedge
          lastedge = edge
        end
      end
    end

    -- two comps
    for _, id in ipairs(twocomps[i]) do
      lastedges = compedges[id][i]
      lastedge = lastedges[#lastedges]
      for _, edge in ipairs(compedges[id][i]) do
        lastedge.links[0] = edge
        edge.links[1] = lastedge
        lastedge = edge
      end
    end
  end

  -- now merge the cycles
  for i = 1, #pair do
    local outeredges = {}
    -- find the biggest face of the tri comps
    if v2 then
      local biggestedge
      local biggestsize
      local biggestindex
      local start = compedges[tricomps[1]][i][1]
      local current = start
      repeat
        local size = self:get_face_size(current)
        if not biggestedge or size > biggestsize
            or (size == biggestsize
            and edgeindices[current] > biggestindex) then
          biggestedge = current
          biggestsize = size
          biggestindex = edgeindices[current]
        end
        current = current.links[0]
      until current == start
      outeredges[1] = biggestedge
    end

    -- now for every two comp
    for _, id in ipairs(twocomps[i]) do
      local biggestedge
      local biggestsize
      local biggestindex
      local start = compedges[id][i][1]
      local current = start
      repeat
        local size = self:get_face_size(current)
        if not biggestedge or size > biggestsize
            or (size == biggestsize
            and edgeindices[current] > biggestindex) then
          biggestedge = current
          biggestsize = size
          biggestindex = edgeindices[current]
        end
        current = current.links[0]
      until current == start
      table.insert(outeredges, biggestedge)
    end

    -- now merge all comps at the outer edges
    local lastedge = outeredges[#outeredges].links[0]
    for _, edge in ipairs(outeredges) do
      local nextlastedge = edge.links[0]
      lastedge.links[1] = edge
      edge.links[0] = lastedge
      lastedge = nextlastedge
    end
  end
end

function E:get_face_size(halfedge)
  local size = 0
  local current = halfedge
  repeat
    size = size + 1
    current = current.twin.links[1]
  until current == halfedge
  return size
end

return E
