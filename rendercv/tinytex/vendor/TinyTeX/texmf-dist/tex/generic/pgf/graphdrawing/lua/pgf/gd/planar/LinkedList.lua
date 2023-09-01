local LinkedList = {}

LinkedList.__index = LinkedList

function LinkedList.new()
  local list = {elements = {}}
  setmetatable(list, LinkedList)
  return list
end

function LinkedList:addback(payload)
  if payload == nil then
    error("Need a payload!", 2)
  end
  local element = { payload = payload }
  if self.head then
    local tail = self.head.prev
    self.head.prev = element
    tail.next = element
    element.next = self.head
    element.prev = tail
  else
    self.head = element
    element.next = element
    element.prev = element
  end
  self.elements[element] = true
  return element
end

function LinkedList:addfront(payload)
  self.head = self:addback(payload)
  return self.head
end

function LinkedList:remove(element)
  if self.elements[element] == nil then
    error("Element not in list!", 2)
  end
  if self.head == element then
    if element.next == element then
      self.head = nil
    else
      self.head = element.next
    end
  end
  element.prev.next = element.next
  element.next.prev = element.prev
  self.elements[element] = nil
end

function LinkedList:popfirst()
  if self.head == nil then
    return nil
  end
  local element = self.head
  if element.next == element then
    self.head = nil
  else
    self.head = element.next
    element.next.prev = element.prev
    element.prev.next = element.next
  end
  self.elements[element] = nil
  return element.payload
end

function LinkedList:poplast()
  if self.head == nil then
    return nil
  end
  self.head = self.head.prev
  return self:popfirst()
end

function LinkedList:first()
  return self.head and self.head.payload
end

function LinkedList:last()
  return self.head and self.head.prev.payload
end

function LinkedList:empty()
  return self.head == nil
end

return LinkedList
