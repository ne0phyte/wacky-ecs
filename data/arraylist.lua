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
  if getmetatable(t) == ArrayList then
    for i=1, t:getHead() do
      if t[i] ~= false then
        self:add(t[i])
      end
    end
  else
    for k,o in pairs(t) do
      self:add(o)
    end
  end
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

function ArrayList:compact(preserveOrder, resize)
  if self.__head > 1 then
    if preserveOrder then
      self:__compactPreserveOrder(resize)
    else
      self:__compactFast(resize)
    end
  end
  if resize then self:resize(self.__head) end
  return self.__head
end

function ArrayList:__compactPreserveOrder()
  local head, tail = 1, self.__head

  -- from head to tail
  while head <= tail do
    if self[head] == false then
      local skip = 1
      -- how many empty indices
      while self[head+skip] == false and head+skip <= tail do
        skip = skip + 1
      end
      -- move rest of array
      for i=head+skip,tail do
        self[i-skip] = self[i]
--         self[i] = false -- TODO this vs loop till self.__head
      end
      -- move head forward and tail backwards
      tail = tail - skip
    else
      head = head + 1
    end
  end
  self.__head = tail
end

function ArrayList:__compactFast()
  local head, tail = 1, self.__head

  -- from head to tail
  for h=1, tail do
    if self[h] == false then
      -- from tail to non-empty index
      for t=tail,h, -1 do
        tail = tail - 1
        if self[t] ~= false then
          self[h] = self[t]
--           self[t] = false -- TODO this vs loop till self.__head
          break
        end
      end
    end
  end
  self.__head = tail
end

return ArrayList
