local ECS = require('wacky-ecs.wacky-ecs')

local mouseCursor = ECS.System.new('mouse_cursor')
mouseCursor.texture = nil

function mouseCursor:wacky_init(world)
  self.texture = nil
  self.entity = ECS.Entity.new(world)
    :add('position', 0, 0)
    :add('size', 4, 4)
    :add('drawable', nil, 100)
    :add('color', 1, 0, 0)
end

function mouseCursor:setTexture(texture, width, height)
  self.entity.drawable.texture = texture
  local size = self.entity.size
  if width and height then
    size.w, size.h = width, height
  else
    size.w, size.h = texture:getDimensions()
  end
end

function mouseCursor:update(entities, dt)
  local camera = self:getWorld():getSystem('camera')
  local input = self:getWorld():getSystem('input')
  local x,y = camera:screenToGame(input:getMouse())
  self.entity.position.x = x
  self.entity.position.y = y
end
