local ArrayList = {}
ArrayList.__index = ArrayList

function ArrayList.new(size)
  local a = setmetatable({__head = 0, __size = 0}, ArrayList)
  if size then
    a:resize(size)
  end
  return a
end

function ArrayList:resetHead()
  self.__head = 0
end

function ArrayList:add(o)
  local head = self.__head + 1
  self[head] = o or false
  self.__head = head
  if head > self.__size then self.__size = head end
  return head
end

function ArrayList:addAll(t)
  for k,o in pairs(t) do
    self:add(o)
  end
  return self
end

function ArrayList:get(i)
  if i < 1 or i > self.__size then error('ArrayList:get() - index out of range: ' .. i) end
  return self[i]
end

function ArrayList:set(i, o)
  if i < 1 or i > self.__size then error('ArrayList:set() - index out of range: ' .. i) end
  self[i] = o or false
end

function ArrayList:remove(i)
  if i < 1 or i > self.__size then error('ArrayList:remove() - index out of range: ' .. i) end
  self[i] = false
end

function ArrayList:clear()
  for i=1, self.__size do
    self[i] = false
  end
  self.__head = 0
end

function ArrayList:resize(size)
  if size then
    if size < 0 then error('ArrayList:resize() - size is negative: ' .. size) end
    if size == self.__size then return end
    if size < self.__size then
      for i=size+1, self.__size do
        self[i] = nil
      end
    else
      for i=self.__size+1, size do
        self[i] = false
      end
    end
    self.__size = size
  else
    self:resize(self.__head)
  end
  if self.__head > self.__size then
    self.__head = self.__size
  end
end

function ArrayList:getSize()
  return self.__size
end

function ArrayList:getHead()
  return self.__head
end

function ArrayList:compact(preserveOrder)
  if preserveOrder then
    self:__compactPreserveOrder()
  else
    self:__compactFast()
  end
end

function ArrayList:__compactPreserveOrder()
  local head, length = 1, self.__size

  -- from head to tail
  while head <= length do
    if self[head] == false then
      local skip = 1
      -- how many empty indices
      while self[head+skip] == false and head+skip <= length do
        skip = skip + 1
      end
      -- move rest of array
      for i=head+skip,length do
        self[i-skip] = self[i]
      end
      -- move head forward and tail backwards
      length = length - skip
    else
      head = head + 1
    end
  end
  self:resize(length)
end

function ArrayList:__compactFast()
  local head, length = 1, self.__size

  -- from head to tail
  for h=1, length do
    if self[h] == false then
      -- from tail to non-empty index
      for t=length,h, -1 do
        length = length - 1
        if self[t] ~= false then
          self[h] = self[t]
          break
        end
      end
    end
  end
  self:resize(length)
end

return ArrayList
