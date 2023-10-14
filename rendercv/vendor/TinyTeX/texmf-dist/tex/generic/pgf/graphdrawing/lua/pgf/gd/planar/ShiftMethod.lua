local SM = {}
require("pgf.gd.planar").ShiftMethod = SM

-- imports
local Embedding = require("pgf.gd.planar.Embedding")

-- create class properties
SM.__index = SM

function SM.new()
  local t = {}
  setmetatable(t, SM)
  return t
end

function SM:init(vertices)
  self.vertices = vertices
  self.xoff = {}
  self.pos = {}
  for _, v in ipairs(vertices) do
    self.pos[v] = {}
  end
  self.left = {}
  self.right = {}
end

function SM:run()
  local v1 = self.vertices[1]
  local v2 = self.vertices[2]
  local v3 = self.vertices[3]

  self.xoff[v1] = 0
  self.pos[v1].y = 0
  self.right[v1] = v3

  self.xoff[v3] = 1
  self.pos[v3].y = 1
  self.right[v3] = v2

  self.xoff[v2] = 1
  self.pos[v2].y = 0

  local n = #self.vertices
  for k = 4, n do
    local vk = self.vertices[k]
    local wplink, wqlink, wp1qsum
    if k ~= n then
      wplink, wqlink, wp1qsum = self:get_attachments(vk)
    else
      wplink, wqlink, wp1qsum = self:get_last_attachments(vk, v1, v2)
    end
    local wp, wq = wplink.target, wqlink.target
    local wp1 = wplink.links[0].target
    local wq1 = wqlink.links[1 - 0].target
    self.xoff[wp1] = self.xoff[wp1] + 1
    self.xoff[wq] = self.xoff[wq] + 1
    wp1qsum = wp1qsum + 2
    self.xoff[vk] = (wp1qsum + self.pos[wq].y - self.pos[wp].y) / 2
    self.pos[vk].y = (wp1qsum + self.pos[wq].y + self.pos[wp].y) / 2
    -- = self.xoff[vk] + self.pos[wp].y ?
    self.right[wp] = vk
    if wp ~= wq1 then
      self.left[vk] = wp1
      self.right[wq1] = nil
      self.xoff[wp1] = self.xoff[wp1] - self.xoff[vk]
    end
    self.right[vk] = wq
    self.xoff[wq] = wp1qsum - self.xoff[vk]
  end
  self.pos[v1].x = 0
  self:accumulate_offset(v1, 0)
  return self.pos
end

function SM:get_attachments(vk)
  local wplink, wqlink
  local wp1qsum = 0
  local start = vk.link
  local startattach = self.xoff[start.target] ~= nil
  local current = start.links[0]
  local last = start
  repeat
    local currentattach = self.xoff[current.target] ~= nil
    local lastattach = self.xoff[last.target] ~= nil
    if currentattach ~= lastattach then
      if currentattach then
        wplink = current
      else
        wqlink = last
      end
      if currentattach == startattach and not startattach then
        break
      end
      currentattach = lastattach
    elseif currentattach then
      wp1qsum = wp1qsum + self.xoff[current.target]
    end
    last = current
    current = current.links[0]
  until last == start
  return wplink, wqlink, wp1qsum
end

function SM:get_last_attachments(vn, v1, v2)
  local wplink, wqlink
  local wp1qsum = 0
  for halfedge in Embedding.adjacency_iterator(vn.link, ccwdir) do
    local target = halfedge.target
    if target == v1 then
      wplink = halfedge
    elseif target == v2 then
      wqlink = halfedge
    end
    wp1qsum = wp1qsum + self.xoff[target]
  end
  return wplink, wqlink, wp1qsum
end

function SM:accumulate_offset(v, x)
  x = x + self.xoff[v]
  self.pos[v].x = x
  local l = self.left[v]
  local r = self.right[v]
  if l then self:accumulate_offset(l, x) end
  if r then self:accumulate_offset(r, x) end
end

return SM
