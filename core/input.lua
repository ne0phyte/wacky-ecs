local ECS = require('wacky-ecs.wacky-ecs')

local input = ECS.System.new('input', nil)

input.mouse = { x = 0, y = 0 }
input.buttons = { false, false, false }
input.wheel = { x = 0, y = 0 }

function input:update_input(entities)
  self.buttons[1] = love.mouse.isDown(1)
  self.buttons[2] = love.mouse.isDown(2)
  self.buttons[3] = love.mouse.isDown(3)
  self.mouse.x, self.mouse.y = love.mouse.getPosition()
--   self.wheel.x, self.wheel.y = 0, 0
end

function input:getMouse()
  return self.mouse.x, self.mouse.y
end

function input:getMouseButton(button)
  return self.buttons[button]
end

function input:getMouseWheel()
  return self.wheel.x, self.wheel.y
end

function input:getGameMouse()
  local camera = self:getWorld():getSystem('camera')
  return camera:screenToGame(self.mouse.x, self.mouse.y)
end
