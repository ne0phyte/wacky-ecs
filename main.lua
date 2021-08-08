local ECS = require('wacky-ecs')
local width, height = love.graphics.getDimensions()

-- Create components for position, velocity, size, color
ECS.Component.new('position', function(x, y)
  return {x = x, y = y}
end)
ECS.Component.new('velocity', function(vx, vy)
  return {vx = vx, vy = vy}
end)
ECS.Component.new('size', function(w, h)
  return {w = w, h = h}
end)
ECS.Component.new('color', function(r, g, b, a)
  return {r, g, b}
end)

-- Create physics system
ECS.System.new('physics', {'position', 'velocity'}, {
  update = function(self, entities, dt)
    for _, e in ipairs(entities) do
      e.velocity.vy = e.velocity.vy + self.gravity * dt
      e.position.x = e.position.x + e.velocity.vx * dt
      e.position.y = e.position.y + e.velocity.vy * dt
    end
  end,
  gravity = 9.81 * 60
})

-- Create system that removes offscreen entities
ECS.System.new('remove_offscreen', {'position', 'size'}, {
  update = function(self, entities, dt)
    for _, e in ipairs(entities) do
      if e.position.x > self.screenWidth
        or e.position.x + e.size.w < 0
        or e.position.y > self.screenHeight
        or e.position.y + e.size.h < 0 then
        e:destroy()
        end
    end
  end,
  screenWidth = width,
  screenHeight = height
})

-- Create system that draws rectangles
ECS.System.new('draw_rectangle', {'position', 'size', 'color'}, {
  draw = function(self, entities, dt)
    for _, e in ipairs(entities) do
      love.graphics.setColor(e.color)
      love.graphics.rectangle('fill',e.position.x, e.position.y, e.size.w, e.size.h)
    end
  end
})

-- Create world
local world = ECS.World.new()
    :addSystem('physics')
    :addSystem('draw_rectangle')
    :addSystem('remove_offscreen')

local stats = {
  update = 0,
  draw = 0,
  frames = 0
}

-- Add 50 entities each frame
function love.update(dt)
  stats.update = love.timer.getTime()
  local angle = love.timer.getTime()*10
  local x = width/2 + math.cos(angle) * 100
  local y = height/2 + math.sin(angle) * 100
  for i=50,1,-1 do
    local dir = math.random(0, math.pi * 2 * 100) / 100
    local e = ECS.Entity.new(world)
      :add('position', x, y, math.random(0, math.pi * 2))
      :add('velocity', math.cos(dir) * 200, -400 + math.sin(dir) * 100)
      :add('size', math.random(1, 10), math.random(1, 10))
      :add('color', math.random(), math.random(), math.random())
  end
  -- commit changes (added/removed/changed entities) from last update
  world:commit()
  -- Calls the physics:update() and remove_offscreen:update() functions
  world:call('update', dt)
  stats.update = love.timer.getTime() - stats.update
end

function love.draw()
  stats.draw = love.timer.getTime()
  love.graphics.clear()
  -- Calls the draw_rectangle:draw() function
  world:call('draw')

  stats.draw = love.timer.getTime() - stats.draw
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle('fill', 0, 0, 100, 80)
  love.graphics.setColor(0,0,0,1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 1, 0)
  love.graphics.print("GC: " .. math.floor(collectgarbage("count")/1024) .. "mb", 1, 16)
  love.graphics.print("Update: " .. math.floor((stats.update)*1000*100)/100, 1, 32)
  love.graphics.print("Draw: " .. math.floor((stats.draw)*1000*100)/100, 1, 48)
  love.graphics.print("Entities: " .. world:getEntityCount(), 1, 64)
end
