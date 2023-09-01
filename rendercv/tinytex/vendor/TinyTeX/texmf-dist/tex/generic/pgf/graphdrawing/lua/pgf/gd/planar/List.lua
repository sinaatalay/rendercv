local List = {}

List.__index = List

function List.new()
  local t = {first = 0, last = -1}
  setmetatable(t, List)
  return t
end

function List:pushleft(value)
  local first = self.first - 1
  self.first = first
  self[first] = value
end

function List:pushright(value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end

function List:popleft()
  local first = self.first
  if first > self.last then error("List is empty") end
  local value = self[first]
  self[first] = nil
  self.first = first + 1
  return value
end

function List:popright()
  local last = self.last
  if self.first > last then error("List is empty") end
  local value = self[last]
  self[last] = nil
  self.last = last - 1
  return value
end

function List:size()
  return self.last - self.first + 1
end

function List:empty()
  return self.last < self.first
end

return List
