local ECS = require('wacky-ecs.wacky-ecs')

local Vector = ECS.Data.Vector

-- ECS.Component.new('position',
--   function(x, y)
--     return {
--       x = x,
--       y = y
--     }
--   end)

ECS.Component.new('position',
  function(x, y)
    return Vector.new(x or 0, y or 0)
  end)

ECS.Component.new('angle',
  function(angle)
    return angle or 0
  end)

ECS.Component.new('velocity',
  function(x, y)
    return Vector.new(x or 0, y or 0)
  end)

-- ECS.Component.new('velocity',
--   function(x, y)
--     return { x = x, y = y }
--   end)

ECS.Component.new('parent', function(parent)
  return parent
end)

ECS.Component.new('movement_speed',
  function(speed)
    return speed
  end)

ECS.Component.new('size',
  function(width, height)
    return Vector.new(width or 0, height or 0)
  end)

-- ECS.Component.new('size',
--   function(width, height)
--     return {
--       w = width,
--       h = height
--     }
--   end)

ECS.Component.new('health', function(health)
  return health
end)

ECS.Component.new('texture', function(texture)
  return texture
end)

ECS.Component.new('color', function(r, g, b, a)
  if r and g and b then return { r, g, b, a }
  elseif type(r) == 'table' then
    return {r[1], r[2], r[3], r[4]}
  else
    return {1, 1, 1}
  end
end)
