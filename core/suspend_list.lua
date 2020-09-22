local ECS = require('wacky-ecs.wacky-ecs')
local shash = require('libs.shash')

ECS.Component.new('suspendable',
  function()
    return {}
  end)

local List = {}
List.__index = List

function List.new()
  return setmetatable({size = 0, __tail = 0}, List)
end

function List:add(o)
  local tail = self.__tail + 1
  self.size = self.size + 1
  self[tail] = o
  self.__tail = tail
  return tail
end

function List:clear()
  for i=1, self.__tail do
    self[i] = nil
  end
  self.size = 0
  self.__tail = 0
end

function List:remove(i)
  self.size = self.size - 1
  self[i] = false
end

function List:getRatio()
  return self.__tail / self.size
end

function List:compact()
  local head, tail = 1, self.__tail

  -- from head to tail
  for h=1, tail do
    if self[h] == false then
      for t=tail,h, -1 do
        if self[t] == false then
          self[t] = nil
          tail = tail - 1
        else
          self[h] = self[t]
          self[t] = nil
          tail = tail - 1
          break
        end
      end
    end
  end
  self.__tail = tail
  self.size = tail
end

local suspend = ECS.System.new('suspend', {'suspendable', 'position', 'size'})
suspend.maxDistance = 200 -- offscreen distance
suspend.suspended = nil

suspend.suspendDt = 0
suspend.suspendInterval = 0.1
suspend.suspendPerUpdate = 100

suspend.wakeupDt = 0
suspend.wakeupInterval = 1

suspend.compactDt = 0
suspend.compactInterval = 1

suspend.enableCallbacks = true

-- TODO suspend/unsuspend on camera movement. figure out width/height = scale changes
suspend.cameraPos = { x = 0, y = 0 }

function suspend:getSuspendedCount()
  return self.suspended.size
end

function suspend:wacky_init()
  self.suspended = List.new()
  self.chunks = Chunklist.new(self.maxDistance)
  self.cameraPos.x, self.cameraPos.y = self:getWorld():getSystem('camera'):getPosition()
end

function suspend:getSuspendedCount()
  return self.suspended.size
end

function suspend:update(entities, dt)
  local world = self:getWorld()
  local camera = world:getSystem('camera')
  local resolveEntityPosition = world:getSystem('render').resolveEntityPosition
  local cx,cy,cw,ch = camera:getVisible()
  if true then
    local dx = self.cameraPos.x - cx
    local dy = self.cameraPos.y - cy
    local dist = math.sqrt(dx^2+dy^2)
    if dist > math.abs(self.maxDistance)*0.9 then
      self.cameraPos.x = cx
      self.cameraPos.y = cy
      self.wakeupDt = self.wakeupInterval + dt
      self.suspendDt = self.suspendInterval + dt
    end
  end

  self.suspendDt = self.suspendDt + dt

  if self.suspendDt > self.suspendInterval then
    prof.push('suspend')
    self.suspendDt = self.suspendDt - self.suspendInterval

--     local count = 0
    for _,e in ipairs(entities) do
      if e ~= false then
        local x,y = resolveEntityPosition(e)
        local dx1 = x + e.size.w + cx
        local dx2 = cw - (x + cx)
        local dy1 = y + e.size.h + cy
        local dy2 = ch - (y + cy)

        if math.min(math.min(dx1, dx2), math.min(dy1, dy2)) < -self.maxDistance then
          -- suspend
          world:removeEntity(e)
          self.suspended:add(e)
        end
--         count = count + 1
--         if count > self.suspendPerUpdate then
--           break
--         end
      end
    end
  prof.pop('suspend')
  end

--   self.wakeupDt = self.wakeupDt + dt
  if self.wakeupDt > self.wakeupInterval then
    prof.push('awake')
    self.wakeupDt = self.wakeupDt - self.wakeupInterval

    for i,e in ipairs(self.suspended) do
      if e ~= false then
        local x,y = resolveEntityPosition(e)
        local dx1 = x + e.size.w + cx
        local dx2 = cw - (x + cx)
        local dy1 = y + e.size.h + cy
        local dy2 = ch - (y + cy)

        if math.min(math.min(dx1, dx2), math.min(dy1, dy2)) > -self.maxDistance then
          -- wake up
          self.suspended:remove(i)
          world:addEntity(e)
        end
      end
    end
    prof.pop('awake')
  end

  self.compactDt = self.compactDt + dt
  if self.compactDt > self.compactInterval then
    self.compactDt = self.compactDt - self.compactInterval
--     if self.suspended:getRatio() > 1.1 then
      prof.push('compact')
      self.suspended:compact()
      prof.pop('compact')
--     end
  end

end

not good, find better solution lol

function suspend:suspendAll(entities)
  local world = self:getWorld()
  local camera = world:getSystem('camera')
  local resolveEntityPosition = world:getSystem('render').resolveEntityPosition
  local cx,cy,cw,ch = camera:getVisible()

  for _,e in ipairs(entities) do
    if e ~= false then
      local x,y = resolveEntityPosition(e)
      local dx1 = x + e.size.w + cx
      local dx2 = cw - (x + cx)
      local dy1 = y + e.size.h + cy
      local dy2 = ch - (y + cy)

      if math.min(math.min(dx1, dx2), math.min(dy1, dy2)) < -self.maxDistance then
        world:removeEntity(e)
        self.suspended:add(e)
      end
    end
  end

end
