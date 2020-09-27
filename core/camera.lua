local ECS = require('wacky-ecs.wacky-ecs')

local camera = ECS.System.new('camera', 'camera')
local Vector = ECS.Data.Vector

function camera:wacky_init(world)
  self.size = Vector.new(1, 1)
  self.screen = Vector.new(1, 1)
  self.scale = Vector.new(1, 1)
  self.pos = Vector.new(0, 0)
  self.preserveRatio = false
  self.zoom = Vector.new(1, 1)
  self:update_camera()
end

function camera:update_camera(entities)
    self.screen.x, self.screen.y = love.graphics.getDimensions()
    self.scale.x = self.screen.x / self.size.x
    self.scale.y = self.screen.y / self.size.y
end

function camera:draw_camera(entities)
  love.graphics.scale(self.scale.x, self.scale.y)
  love.graphics.translate(self.pos.x, self.pos.y)

--   love.graphics.translate(self.size.w/2, self.size.h/2)
--   love.graphics.scale(self.zoom.x, self.zoom.y)
--   love.graphics.translate(-self.size.w/2, -self.size.h/2)
end

function camera:setPreserveRatio(preserveRatio)
  self.preserveRatio = preserveRatio
end

function camera:screenToGame(x, y)
  return -self.pos.x + x / self.scale.x, -self.pos.y + y / self.scale.y
end

function camera:screenToGameOrigin(x, y)
  return x / self.scale.x, y / self.scale.y
end

function camera:getVisible()
  return
    self.pos.x,
    self.pos.y,
    self.size.x,
    self.size.y
end

function camera:setPosition(x, y)
  self.pos.x, self.pos.y = x, y
end

function camera:getPosition()
  return self.pos.x, self.pos.y
end

function camera:getSize()
  return self.size.x, self.size.y
end

function camera:setSize(w, h)
  self.size.x, self.size.y = w, h
end

function camera:getScreen()
  return self.screen.x, self.screen.y
end

function camera:isVisible(x, y, w, h)
  local x = x + self.pos.x
  local y = y + self.pos.y
  return x+w > 0 and x < self.size.x and
         y+h > 0 and y < self.size.y
end

-- function camera:setZoom(x, y)
--   self.zoom.x = x
--   self.zoom.y = y
-- end
