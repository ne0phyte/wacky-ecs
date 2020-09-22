local HashList = {}
HashList.__index = HashList

function HashList.new(objects)
  local l = setmetatable({ size = 0}, HashList)
  if type(objects) == 'table' then l:addAll(objects) end
  return l
end

function HashList:add(object, nokey)
  if self[object] then return end
  local idx = self.size + 1
  self[idx] = object
  if not nokey then
    self[object] = idx
  end
  self.size  = idx
  return self
end

function HashList:remove(object)
  local idx = self[object]
  if not idx then return end
  local size = self.size

  if idx ~= size then
    local last = self[size]
    self[idx], self[last] = last, idx
  end

  self[size] = nil
  self[object] = nil
  self.size = size - 1
  return self
end

function HashList:addAll(objects)
  for k,v in pairs(objects) do
    self:add(v)
  end
  return self
end

function HashList:has(object)
  return self[object] ~= nil
end

function HashList:clear()
  for i=self.size,1,-1 do
    local o = self[i]
    self[i] = nil
    self[o] = nil
  end
  self.size = 0
end

function HashList:get(i)
  return self[i]
end

function HashList:getSize()
  return self.size
end

return HashList
