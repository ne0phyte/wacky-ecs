local ECS = require('wacky-ecs.wacky-ecs')
local Vector = ECS.Data.Vector

ECS.Component.new('particle_emitter',
  function(texture, lifetime, rate, speed, dirX, dirY, offX, offY)
    return {
      texture = texture,
      lifetime = lifetime or 1,
      rate = rate or 1,
      dt = math.random() * lifetime,
      speed = speed or 1,
      direction = Vector.new(dirX or 0, dirY or 0),
      offset = Vector.new(offX or 0, offY or 0),
      size = Vector.new(width or texture:getWidth(), height or texture:getHeight())
    }
  end)

ECS.Component.new('particle',
  function(texture, lifetime)
    return {
      texture = texture,
      lifetime = lifetime or 1,
      dt = 0
    }
  end)

local particlesystem = ECS.System.new('particles', {'particle_emitter'})

local function poolCreateParticle()
  return ECS.Entity.new()
    :add('position')
    :add('size')
    :add('drawable')
    :add('velocity')
    :add('particle')
end

function particlesystem:wacky_init(world)
  self.particles = ECS.Data.ArrayList.new(1000)
  self.pool = ECS.Util.Pool.new(poolCreateParticle, nil, 1000)
end

function particlesystem:update(entities, dt)
  local particles = self.particles
  self:__updateParticles(dt)

  for _,e in ipairs(entities) do
    local emitter = e.particle_emitter
    local x = e.position.x + e.size.x/2 + emitter.offset.x
    local y = e.position.y + e.size.y/2 + emitter.offset.y

    emitter.dt = emitter.dt + dt
    while emitter.dt > emitter.rate do
      emitter.dt = emitter.dt - emitter.rate
      local a = -e.angle + (math.random()-0.5)
      local dx =  math.cos(a) * emitter.speed + emitter.direction.x * emitter.speed
      local dy =  math.sin(a) * emitter.speed + emitter.direction.y * emitter.speed
      -- create particle

      local p = self.pool:get()
      p.position:set(x, y)
      p.size:vset(emitter.size)
      p.velocity:set(dx, dy)
      p.drawable.texture = emitter.texture
      p.drawable.z = e.drawable.z - 0.001
      p.particle.texture = emitter.texture
      p.particle.lifetime = emitter.lifetime
      p.particle.dt = 0

      particles:add(p)
    end
  end
  self:getWorld():getSystem('render'):addDrawables(particles)
end

function particlesystem:__updateParticles(dt)
  local particles = self.particles
  if particles:getHead() == 0 then return end

  local removed = 0
  for i=1, particles:getHead() do
    if particles[i] ~= false then
      local e = particles[i]
      local p = e.particle
      p.dt = p.dt + dt
      if p.dt > p.lifetime then
        particles:remove(i)
        self.pool:put(e)
        removed = removed + 1
      else
        e.position.x = e.position.x + e.velocity.x * dt
        e.position.y = e.position.y + e.velocity.y * dt
      end
    end
  end
  if removed > 0 then
    particles:compact()
  end
end
