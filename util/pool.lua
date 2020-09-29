local Pool = {}
Pool.__index = Pool

function Pool.new(newFunc, initFunc, size)
  size = size or 16
  local p = setmetatable({
    __new = newFunc,
    __init = initFunc,
    __size = 0,
  }, Pool)
  if size then
    for i=1, size do
      p[i] = newFunc()
    end
  end
  return p
end

function Pool:get(...)
  local o = self[#self]
  if o then
    self[#self] = nil
  else
    o = self.__new()
  end
  if self.__init then
    self.__init(o, ...)
  end
  return o
end

function Pool:put(o)
  self[#self + 1] = o
end

return Pool
