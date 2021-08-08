local ECS = require('wacky-ecs.wacky-ecs')

ECS.Component.new('physics',
  function(body, shape, fixture)
    return {
      body = body,
      shape = shape,
      fixture = fixture
    }
  end)

local physics = ECS.System.new('physics', {'position', 'size', 'physics'})

function physics:wacky_init(world)
  self.gravity = ECS.Data.Vector.new(0, 9.81)
  self.meter = 32
  self.world = love.physics.newWorld(0, 0, true)
  self:setGravity(self.gravity.x, self.gravity.y)
  self:setMeter(self.meter)
--   self.world:setCallbacks(beginContactCallback, nil, nil, postSolveCallback )
end

function physics:getPhysicsWorld()
  return self.world
end

function physics:setGravity(x, y)
  self.gravity:set(x, y)
  self.world:setGravity(x*self.meter, y*self.meter)
end

function physics:setMeter(scale)
  self.meter = 32
  love.physics.setMeter(scale)
  self:setGravity(self.gravity.x, self.gravity.y)
end

function physics:update(entities, dt)
  self.world:update(dt)
  for _,e in ipairs(entities) do
    local position = e.position
    local physics = e.physics
    local body = physics.body
--     if physics.fixture:isSensor() then
--       local x,y = position.x, position.y
--       body:setPosition(x, y)
--       body:setAngle(e.angle)
--     else
      local x,y = body:getPosition()
      position:set(x,y)
      e.angle = body:getAngle()
      if e.velocity then
        e.velocity:set(body:getLinearVelocity())
      end
  end
end

function physics:draw_debug(entities)
  love.graphics.setColor(1,0,1,0.8)
  for _,body in ipairs(self.world:getBodies()) do
    for _, fixture in pairs(body:getFixtures()) do
      local shape = fixture:getShape()

      if shape:typeOf("CircleShape") then
          local cx, cy = body:getWorldPoints(shape:getPoint())
          love.graphics.circle("line", cx, cy, shape:getRadius())
      elseif shape:typeOf("PolygonShape") then
          love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
      else
          love.graphics.line(body:getWorldPoints(shape:getPoints()))
      end
    end
  end

  love.graphics.setColor(1,0,0,1)
  for _,body in ipairs(self.world:getBodies()) do
    for _,contact in ipairs(body:getContacts()) do
      local x1, y1, x2, y2 = contact:getPositions()
      local nx, ny = contact:getNormal()
      if x1 and y1 then
        love.graphics.circle('fill', x1, y1, 2)
      end
    end
  end
end
