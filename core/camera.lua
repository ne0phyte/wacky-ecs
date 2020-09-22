local ECS = require('wacky-ecs.wacky-ecs')

local camera = ECS.System.new('camera', 'camera')

camera.size = { w = 1, h = 1 }
camera.screen = { w = width, h = height }
camera.scale = { x = 1, y = 1 }
camera.pos = { x = 0, y = 0 }
camera.preserveRatio = false
camera.zoom = { x = 1, y = 1 }

function camera:update_camera(entities)
    self.screen.w, self.screen.h = love.graphics.getDimensions()
    self.scale.x = self.screen.w / self.size.w
    self.scale.y = self.screen.h / self.size.h
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
    self.size.w,
    self.size.h
end

function camera:setPosition(x, y)
  self.pos.x, self.pos.y = x, y
end

function camera:getPosition()
  return self.pos.x, self.pos.y
end

function camera:getSize()
  return self.size.w, self.size.h
end

function camera:getScreen()
  return self.screen.w, self.screen.h
end

function camera:isVisible(x, y, w, h)
  x = x + self.pos.x
  y = y + self.pos.y
  return x+w > 0 and x < self.size.w and
         y+h > 0 and y < self.size.h
end

function camera:setZoom(x, y)
  self.zoom.x = x
  self.zoom.y = y
end
