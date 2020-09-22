local ECS = require('wacky-ecs.wacky-ecs')

ECS.Component.new('animation',
  function(texture, quads, current, animations)
    return {
      texture = texture,
      quads = quads,
      animations = animations,
      current = current or 'default',
      time = 0,
      frame = 1
    }
  end)

local animation = ECS.System.new('animation', {'drawable', 'animation'})

function animation:update(entities, dt)
--   local time = love.timer.getTime()
  for _,e in ipairs(entities) do
    local a = e.animation
    local d = e.drawable
    local current = a.animations[a.current]

--     if time - a.time > current.time then
--       a.time = time + ((time - a.time) % current.time)
--       if a.frame < #current.frames or current.loop then
--         a.frame = 1 + (a.frame % #current.frames)
--       end
--     end

    a.time = a.time + dt
    if a.time > current.time then
      if a.frame < #current.frames or current.loop then
        a.frame = 1 + (a.frame % #current.frames)
      end
      a.time = a.time - current.time
    end
    d.texture = a.texture
    d.quad = a.quads[current.frames[a.frame]]
  end
end
