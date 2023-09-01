
local PDP = {}
require("pgf.gd.planar").PDP = PDP

-- Imports
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare
local Storage = require "pgf.gd.lib.Storage"
local Coordinate = require "pgf.gd.model.Coordinate"
local Path = require "pgf.gd.model.Path"
---
PDP.__index = PDP

function PDP.new(ugraph, embedding,
        delta, gamma, coolingfactor,
        expiterations,
        startrepexp, endrepexp,
        startattexp, endattexp,
        appthreshold, stretchthreshold,
        stresscounterthreshold,
        numdivisions)
  local t = {
    ugraph = ugraph,
    embedding = embedding,
    delta = delta ,
    gamma = gamma,
    coolingfactor = coolingfactor,
    expiterations = expiterations,
    startrepexp = startrepexp,
    endrepexp = endrepexp,
    startattexp = startattexp,
    endattexp = endattexp,
    appthreshold = appthreshold,
    stretchthreshold = stretchthreshold,
    stresscounterthreshold = stresscounterthreshold,
    numdivisions = numdivisions,
    posxs = {},
    posys = {},
    cvsxs = {},
    cvsys = {},
    embeddingedges = {},
    edgeids = {},
    numedgeids = 0,
    vertexids = {},
    numvertexids = 0,
    vertexpairs1 = {},
    vertexpairs2 = {},
    pairconnected = {},
    edgepairsvertex = {},
    edgepairsedge = {},
    edgevertex1 = {},
    edgevertex2 = {},
    edgedeprecated = {},
    subdivisionedges = {},
    subdivisionvertices = {},
    temperature = 1,
  }

  setmetatable(t, PDP)
  return t
end

function PDP:run()
  self:normalize_size()
  self:find_force_pairs()

  local delta = self.delta
  local gamma = self.gamma
  local coolingfactor = self.coolingfactor
  local expiterations = self.expiterations
  local startrepexp = self.startrepexp
  local endattexp = self.endattexp
  local startattexp = self.startattexp
  local endrepexp = self.endrepexp

  local vertexpairs1 = self.vertexpairs1
  local vertexpairs2 = self.vertexpairs2
  local pairconnected = self.pairconnected
  local edgepairsvertex = self.edgepairsvertex
  local edgepairsedge = self.edgepairsedge
  local edgevertex1 = self.edgevertex1
  local edgevertex2 = self.edgevertex2
  local edgedeprecated = self.edgedeprecated

  local forcexs = {}
  local forceys = {}
  local posxs = self.posxs
  local posys = self.posys
  local cvsxs = self.cvsxs
  local cvsys = self.cvsys
  local numcvs = {}
  for i, v in ipairs(self.embedding.vertices) do
    cvsxs[i] = {}
    cvsys[i] = {}
    posxs[i] = v.inputvertex.pos.x
    posys[i] = v.inputvertex.pos.y
  end

  local numorigvertices = self.numvertexids
  local numorigedges = self.numedgeids
  local numdivisions = self.numdivisions
  local divdelta = delta / (numdivisions + 1)
  local stresscounter = {}
  for i = 1, self.numedgeids do
    stresscounter[i] = 0
  end

  local appthreshold = self.appthreshold
  local stretchthreshold = self.stretchthreshold
  local stresscounterthreshold = self.stresscounterthreshold

  for i = 1, numorigedges do
    local iv1 = self.embedding.vertices[edgevertex1[i]].inputvertex
    local iv2 = self.embedding.vertices[edgevertex2[i]].inputvertex
    local arc = self.ugraph:arc(iv1, iv2)
    --TODO subdivide edge if desired
    --self:subdivide_edge(i)
  end

  -- main loop
  local iteration = 0
  repeat
    iteration = iteration + 1
    local temperature = self.temperature
    local ratio = math.min(1, iteration / expiterations)
    local repexp = startrepexp + (endrepexp - startrepexp) * ratio
    local attexp = startattexp + (endattexp - startattexp) * ratio
    for i = 1, self.numvertexids do
      forcexs[i] = 0
      forceys[i] = 0
      numcvs[i] = 0
    end
    -- vertex-vertex forces
    for i = 1, #vertexpairs1 do
      local id1 = vertexpairs1[i]
      local id2 = vertexpairs2[i]
      local diffx = posxs[id2] - posxs[id1]
      local diffy = posys[id2] - posys[id1]
      local dist2 = diffx * diffx + diffy * diffy
      local dist = math.sqrt(dist2)
      local dirx = diffx / dist
      local diry = diffy / dist
      assert(dist ~= 0)

      local useddelta = delta
      local hasdivvertex = id1 > numorigvertices or id2 > numorigvertices

      -- calculate attractive force
      if pairconnected[i] then
        if hasdivvertex then
          useddelta = divdelta
        end
        local mag = (dist / useddelta) ^ attexp * useddelta
        local fax = mag * dirx
        local fay = mag * diry
        forcexs[id1] = forcexs[id1] + fax
        forceys[id1] = forceys[id1] + fay
        forcexs[id2] = forcexs[id2] - fax
        forceys[id2] = forceys[id2] - fay
      elseif hasdivvertex then
        useddelta = gamma
      end

      -- calculate repulsive force
      local mag = (useddelta / dist) ^ repexp * useddelta
      local frx = mag * dirx
      local fry = mag * diry
      forcexs[id1] = forcexs[id1] - frx
      forceys[id1] = forceys[id1] - fry
      forcexs[id2] = forcexs[id2] + frx
      forceys[id2] = forceys[id2] + fry
    end

    -- edge-vertex forces and collisions
    for i = 1, #edgepairsvertex do
      local edgeid = edgepairsedge[i]
      if not edgedeprecated[edgeid] then
        local id1 = edgepairsvertex[i]
        local id2 = edgevertex1[edgeid]
        local id3 = edgevertex2[edgeid]
        assert(id2 ~= id1 and id3 ~= id1)

        local abx = posxs[id3] - posxs[id2]
        local aby = posys[id3] - posys[id2]
        local dab2 = abx * abx + aby * aby
        local dab = math.sqrt(dab2)
        assert(dab ~= 0)
        local abnx = abx / dab
        local abny = aby / dab
        local avx = posxs[id1] - posxs[id2]
        local avy = posys[id1] - posys[id2]
        local daiv = abnx * avx + abny * avy
        local ivx = posxs[id2] + abnx * daiv
        local ivy = posys[id2] + abny * daiv
        local vivx = ivx - posxs[id1]
        local vivy = ivy - posys[id1]
        local dviv2 = vivx * vivx + vivy * vivy
        local dviv = math.sqrt(dviv2)
        local afactor, bfactor = 1, 1
        local cvx
        local cvy
        if daiv < 0 then
          cvx = -avx / 2
          cvy = -avy / 2
          local norm2 = cvx * cvx + cvy * cvy
          bfactor = 1 + (cvx * abx + cvy * aby) / norm2
        elseif daiv > dab then
          cvx = (abx - avx) / 2
          cvy = (aby - avy) / 2
          local norm2 = cvx * cvx + cvy * cvy
          afactor = 1 - (cvx * abx + cvy * aby) / norm2
        else
          if edgeid < numorigedges
              and dviv < gamma * appthreshold
              and dab > delta * stretchthreshold then
            stresscounter[edgeid] = stresscounter[edgeid] + 1
          end
          assert(dviv > 0)
          cvx = vivx / 2
          cvy = vivy / 2
          -- calculate edge repulsive force
          local dirx = -vivx / dviv
          local diry = -vivy / dviv
          local mag = (gamma / dviv) ^ repexp * gamma
          local fex = mag * dirx
          local fey = mag * diry
          local abratio = daiv / dab
          forcexs[id1] = forcexs[id1] + fex
          forceys[id1] = forceys[id1] + fey
          forcexs[id2] = forcexs[id2] - fex * (1 - abratio)
          forceys[id2] = forceys[id2] - fey * (1 - abratio)
          forcexs[id3] = forcexs[id3] - fex * abratio
          forceys[id3] = forceys[id3] - fey * abratio
        end
        local nv = numcvs[id1] + 1
        local na = numcvs[id2] + 1
        local nb = numcvs[id3] + 1
        numcvs[id1] = nv
        numcvs[id2] = na
        numcvs[id3] = nb
        cvsxs[id1][nv] = cvx
        cvsys[id1][nv] = cvy
        cvsxs[id2][na] = -cvx * afactor
        cvsys[id2][na] = -cvy * afactor
        cvsxs[id3][nb] = -cvx * bfactor
        cvsys[id3][nb] = -cvy * bfactor
      end
    end

    -- clamp forces
    local scalefactor = 1
    local collision = false
    for i = 1, self.numvertexids do
      local forcex = forcexs[i]
      local forcey = forceys[i]
      forcex = forcex * temperature
      forcey = forcey * temperature
      forcexs[i] = forcex
      forceys[i] = forcey
      local forcenorm2 = forcex * forcex + forcey * forcey
      local forcenorm = math.sqrt(forcenorm2)
      scalefactor = math.min(scalefactor, delta * 3 * temperature / forcenorm)
      local cvys = cvsys[i]
      for j, cvx in ipairs(cvsxs[i]) do
        local cvy = cvys[j]
        local cvnorm2 = cvx * cvx + cvy * cvy
        local cvnorm = math.sqrt(cvnorm2)
        local projforcenorm = (cvx * forcex + cvy * forcey) / cvnorm
        if projforcenorm > 0 then
          local factor = cvnorm * 0.9 / projforcenorm
          if factor < scalefactor then
            scalefactor = factor
            collision = true
          end
        end
      end
    end
    local moved = false
    for i = 1, self.numvertexids do
      local forcex = forcexs[i] * scalefactor
      local forcey = forceys[i] * scalefactor
      posxs[i] = posxs[i] + forcex
      posys[i] = posys[i] + forcey
      local forcenorm2 = forcex * forcex + forcey * forcey
      if forcenorm2 > 0.0001 * delta * delta then moved = true end
    end

    -- subdivide stressed edges
    if numdivisions > 0 then
      for i = 1, numorigedges do
        if stresscounter[i] > stresscounterthreshold then
          self:subdivide_edge(i)
          stresscounter[i] = 0
        end
      end
    end
    self.temperature = self.temperature * coolingfactor
  until not collision and not moved
  print("\nfinished PDP after " .. iteration .. " iterations")

  -- write the positions back
  for i, v in ipairs(self.embedding.vertices) do
    v.inputvertex.pos.x = posxs[i]
    v.inputvertex.pos.y = posys[i]
  end

  -- route the edges
  for i = 1, self.numedgeids do
    if self.subdivisionvertices[i] then
      local iv1 = self.embedding.vertices[self.edgevertex1[i]].inputvertex
      local iv2 = self.embedding.vertices[self.edgevertex2[i]].inputvertex
      local arc = self.ugraph:arc(iv1, iv2)
      local p = Path.new()
      p:appendMoveto(arc.tail.pos:clone())
      for _, vid in ipairs(self.subdivisionvertices[i]) do
        p:appendLineto(self.posxs[vid], self.posys[vid])
      end
      p:appendLineto(arc.head.pos:clone())
      arc.path = p
    end
  end
end

function PDP:subdivide_edge(edgeid)
  assert(self.subdivisionedges[edgeid] == nil)
  local numdivisions = self.numdivisions
  local subdivisionedges = {}
  local subdivisionvertices = {}
  local id1 = self.edgevertex1[edgeid]
  local id2 = self.edgevertex2[edgeid]
  local x1 = self.posxs[id1]
  local y1 = self.posys[id1]
  local x2 = self.posxs[id2]
  local y2 = self.posys[id2]
  local prevvertexid = id1
  for i = 1, numdivisions do
    -- create new edge and vertex
    local newvertexid1 = self.numvertexids + i
    table.insert(subdivisionvertices, newvertexid1)
    self.posxs[newvertexid1] = (x1 * (numdivisions + 1 - i) + x2 * i)
        / (numdivisions + 1)
    self.posys[newvertexid1] = (y1 * (numdivisions + 1 - i) + y2 * i)
        / (numdivisions + 1)
    self.cvsxs[newvertexid1] = {}
    self.cvsys[newvertexid1] = {}

    local newedgeid = self.numedgeids + i
    table.insert(subdivisionedges, newedgeid)
    table.insert(self.edgevertex1, prevvertexid)
    table.insert(self.edgevertex2, newvertexid1)
    prevvertexid = newvertexid1

    -- pair the new vertex
    -- with first vertex of the edge being divided
    table.insert(self.vertexpairs1, self.edgevertex1[edgeid])
    table.insert(self.vertexpairs2, newvertexid1)
    table.insert(self.pairconnected, i == 1)

    -- with second vertex of the edge being divided
    table.insert(self.vertexpairs1, self.edgevertex2[edgeid])
    table.insert(self.vertexpairs2, newvertexid1)
    table.insert(self.pairconnected, i == numdivisions)

    -- with each other
    for j = i + 1, numdivisions do
      local newvertexid2 = self.numvertexids + j
      table.insert(self.vertexpairs1, newvertexid1)
      table.insert(self.vertexpairs2, newvertexid2)
      table.insert(self.pairconnected, j == i + 1)
    end

    -- with new edges
    -- before vertex
    for j = 1, i - 1 do
      local newedgeid = self.numedgeids + j
      table.insert(self.edgepairsvertex, newvertexid1)
      table.insert(self.edgepairsedge, newedgeid)
    end
    -- after vertex
    for j = i + 2, numdivisions + 1 do
      local newedgeid = self.numedgeids + j
      table.insert(self.edgepairsvertex, newvertexid1)
      table.insert(self.edgepairsedge, newedgeid)
    end

    -- pair the new edges with vertices of the edge being divided
    if i > 1 then
      table.insert(self.edgepairsvertex, id1)
      table.insert(self.edgepairsedge, newedgeid)
    end
    table.insert(self.edgepairsvertex, id2)
    table.insert(self.edgepairsedge, newedgeid)
  end
  -- create last edge
  table.insert(subdivisionedges, self.numedgeids + numdivisions + 1)
  table.insert(self.edgevertex1, prevvertexid)
  table.insert(self.edgevertex2, id2)

  -- pair last edge with first vertex of the edge being divided
  table.insert(self.edgepairsvertex, id1)
  table.insert(self.edgepairsedge, self.numedgeids + numdivisions + 1)

  self.subdivisionedges[edgeid] = subdivisionedges
  self.subdivisionvertices[edgeid] = subdivisionvertices

  -- pair new edges and vertices with existing edges and vertices
  local sameface = false
  local start = self.embeddingedges[edgeid]
  local twin = start.twin
  local donevertices = { [start.target] = true, [twin.target] = true }
  local doneedges = { [start] = true, [twin] = true }
  local current = start.twin.links[1]
  for twice = 1, 2 do
    while current ~= start do
      if current == twin then
        sameface = true
      end

      -- pair edge with the new vertices
      -- or pair subdivision of edge with new vertices and edges
      if not doneedges[current] then
        local currentedgeid = self.edgeids[current]
        if self.subdivisionvertices[currentedgeid] then
          for _, vid in ipairs(self.subdivisionvertices[currentedgeid]) do
            for i = 1, numdivisions do
              local newvertexid = self.numvertexids + i
              table.insert(self.vertexpairs1, vid)
              table.insert(self.vertexpairs2, newvertexid)
              self.pairconnected[#self.vertexpairs1] = false
            end
            for i = 1, numdivisions + 1 do
              local newedgeid = self.numedgeids + i
              table.insert(self.edgepairsvertex, vid)
              table.insert(self.edgepairsedge, newedgeid)
            end
          end
          for _, eid in ipairs(self.subdivisionedges[currentedgeid]) do
            for i = 1, numdivisions do
              local newvertexid = self.numvertexids + i
              table.insert(self.edgepairsvertex, newvertexid)
              table.insert(self.edgepairsedge, eid)
            end
          end
        else
          for i = 1, numdivisions do
            local newvertexid = self.numvertexids + i
            table.insert(self.edgepairsvertex, newvertexid)
            table.insert(self.edgepairsedge, currentedgeid)
          end
        end
        doneedges[current] = true
      end

      -- pair target vertex with the new vertices and edges
      local vertexid = self.vertexids[current.target]
      if not donevertices[current.target] then
        for i = 1, numdivisions do
          local newvertexid = self.numvertexids + i
          table.insert(self.vertexpairs1, vertexid)
          table.insert(self.vertexpairs2, newvertexid)
          self.pairconnected[#self.vertexpairs1] = false
        end
        for i = 1, numdivisions + 1 do
          local newedgeid = self.numedgeids + i
          table.insert(self.edgepairsvertex, vertexid)
          table.insert(self.edgepairsedge, newedgeid)
        end
      end
      current = current.twin.links[1]
    end
    start = self.embeddingedges[edgeid].twin
    current = start.twin.links[1]
    if sameface then
      break
    end
  end

  self.edgedeprecated[edgeid] = true
  self.numvertexids = self.numvertexids + numdivisions
  self.numedgeids = self.numedgeids + numdivisions + 1
end

function PDP:find_force_pairs()
  local donevertices = {}
  -- number all vertices
  local vertexids = self.vertexids
  for i, v in ipairs(self.embedding.vertices) do
    vertexids[v] = i
  end
  self.numvertexids = #self.embedding.vertices

  local edgeids = self.edgeids
  local numedgeids = 0
  -- number all edges
  for _, v in ipairs(self.embedding.vertices) do
    local id = vertexids[v]
    local start = v.link
    local current = start
    repeat
      local targetid = vertexids[current.target]
      if edgeids[current] == nil then
        table.insert(self.edgevertex1, id)
        table.insert(self.edgevertex2, targetid)
        numedgeids = numedgeids + 1
        edgeids[current] = numedgeids
        edgeids[current.twin] = numedgeids
        self.embeddingedges[numedgeids] = current
      end
      current = current.links[0]
    until current == start
  end

  -- find all force pairs
  for _, v in ipairs(self.embedding.vertices) do
    local id = vertexids[v]
    donevertices[id] = true
    local vertexset = {}
    local edgeset = {}
    local start = v.link
    repeat
      local targetid = vertexids[start.target]
      if vertexset[targetid] == nil and not donevertices[targetid] then
        table.insert(self.pairconnected, true)
        table.insert(self.vertexpairs1, id)
        table.insert(self.vertexpairs2, targetid)
        vertexset[targetid] = true
      end
      local current = start.twin.links[1]
      while current.target ~= v do
        local targetid = vertexids[current.target]
        if vertexset[targetid] == nil and not donevertices[targetid] then
          table.insert(self.pairconnected, self.ugraph:arc(v.inputvertex, current.target.inputvertex) ~= nil)
          table.insert(self.vertexpairs1, id)
          table.insert(self.vertexpairs2, targetid)
          vertexset[targetid] = true
        end
        if edgeset[current] == nil then
          table.insert(self.edgepairsvertex, id)
          table.insert(self.edgepairsedge, edgeids[current])
          edgeset[current] = true
          edgeset[current.twin] = true
        end
        current = current.twin.links[1]
      end
      start = start.links[0]
    until start == v.link
  end

  self.numedgeids = numedgeids
end

function PDP:normalize_size()
  local minx = math.huge
  local maxx = -math.huge
  local miny = math.huge
  local maxy = -math.huge

  for _, v in ipairs(self.ugraph.vertices) do
    minx = math.min(minx, v.pos.x)
    maxx = math.max(maxx, v.pos.x)
    miny = math.min(miny, v.pos.y)
    maxy = math.max(maxy, v.pos.y)
  end

  local area = (maxx - minx) * (maxy - miny)
  local gridarea = #self.ugraph.vertices * self.delta * self.delta

  local scale = math.sqrt(gridarea) / math.sqrt(area)

  for _, v in ipairs(self.ugraph.vertices) do
    v.pos = v.pos * scale
  end
end

-- done

return PDP
