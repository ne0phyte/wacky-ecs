local ECS = require('wacky-ecs.wacky-ecs')

ECS.Component.new('suspendable',
  function()
    return {}
  end)

local Chunklist = {}
Chunklist.__index = Chunklist

function Chunklist.new(grid, chunkLength)
  return setmetatable({
    grid = grid,
    size = 0,
    chunkLength = chunkLength or 32,
    chunks = {}
  }, Chunklist)
end

function Chunklist:add(obj, x, y)
  local gx = math.floor(x / self.grid)
  local gy = math.floor(y / self.grid)
  if not self.chunks[gx] then
    self.chunks[gx] = {}
  end
  if not self.chunks[gx][gy] then
    self.chunks[gx][gy] = ECS.Data.ArrayList.new(self.chunkLength)
  end
  self.chunks[gx][gy]:add(obj)
  self.size = self.size + 1
end

function Chunklist:getChunk(x, y)
  local detach = detach or false
  local gx = math.floor(x / self.grid)
  local gy = math.floor(y / self.grid)
  if self.chunks[gx] and self.chunks[gx][gy] then
    return self.chunks[gx][gy]
  end
end

function Chunklist:clearChunk(x,y)
  local list = self:getChunk(x, y)
  if list then
    self.size = self.size - list:getHead()
--     list:clear()
    list:resetHead()
  end
end

function Chunklist:free()
  for kx,cx in pairs(self.chunks) do
    local allEmpty = true
    for ky,cy in pairs(cx) do
      if cy:getHead() == 0 then
        cx[ky] = nil
      else
        allEmpty = false
      end
    end
    if allEmpty then
      self.chunks[kx] = nil
    end
  end
end

local suspend = ECS.System.new('suspend', {'suspendable', 'position', 'size'})

function suspend:wacky_init()
  self.gridSize = 64
  self.chunkSize = 16
  self.preload = 2
  self.chunks = Chunklist.new(self.gridSize, self.chunkSize)

  self.suspendDt = 0
  self.suspendInterval = 0.1
end

function suspend:gc()
  self.chunks:free()
end

function suspend:getSuspendedCount()
  return self.chunks.size
end

function suspend:update(entities, dt)
  local world = self:getWorld()
  local camera = world:getSystem('camera')
  local resolveEntityPosition = world:getSystem('render').resolveEntityPosition
  local cx,cy,cw,ch = camera:getVisible()

  local ox = -(self.preload+math.floor(cx / self.gridSize)) * self.gridSize
  local oy = -(self.preload+math.floor(cy / self.gridSize)) * self.gridSize

  local sx = (self.preload+math.floor(cw / self.gridSize)) * self.gridSize
  local sy = (self.preload+math.floor(ch / self.gridSize)) * self.gridSize

  prof.push('awake')
  for gridx = ox, ox+sx, self.gridSize do
    for gridy = oy, oy+sy, self.gridSize do
      local list = self.chunks:getChunk(gridx, gridy)
      if list then
        local head = list:getHead()
        for i=1,head do
          world:addEntity(list[i])
        end
        self.chunks:clearChunk(gridx, gridy)
      end
    end
  end
  prof.pop('awake')

  self.suspendDt = self.suspendDt + dt
  if self.suspendDt > self.suspendInterval then
    prof.push('suspend')
    self.suspendDt = self.suspendDt - self.suspendInterval

    ox = ox - self.gridSize
    oy = oy - self.gridSize
    sx = ox + sx + self.gridSize * 2
    sy = oy + sy + self.gridSize * 2
    for _,e in ipairs(entities) do
      if e ~= false then
        local x, y = resolveEntityPosition(e)
        if (x < ox or x > sx) or (y < oy or y > sy) then
          world:removeEntity(e)
          self.chunks:add(e, x, y)
        end
      end
    end
    prof.pop('suspend')
  end
end

-- function suspend:suspendAll(entities)
--   local world = self:getWorld()
--   local camera = world:getSystem('camera')
--   local resolveEntityPosition = world:getSystem('render').resolveEntityPosition
--   local cx,cy,cw,ch = camera:getVisible()

--   for _,e in ipairs(entities) do
--     local x,y = resolveEntityPosition(e)
--     world:removeEntity(e)
--     self.chunks:add(e, x, y)
--   end
-- end
