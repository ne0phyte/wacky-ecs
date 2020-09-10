# wacky-ecs

wacky-ecs is a very simple ECS for LÖVE.

---

**WORK IN PROGRESS**

---

## Table of Contents

[Installation](#installation)  
[API](#api)  

- [Components](#components)  
- [Entities](#entities)  
- [Systems](#systems)
- [Worlds](#worlds)

[Complete example](#complete-example)

---

## Installation

Clone the repository into your project directory and require it:

`local ECS = require('wacky-ecs.wacky-ecs')`

---

## API

### Components

Components are nothing but data (a lua table) attached to an entity. Each component has a name and any number of fields. 

To populate a components fields in a convenient way you have to provide a function when creating a new component:

```lua
ECS.Component.new('position', function(component, x, y)
  component.y = y
  component.x = x
end)
```

If your component doesn't need named properties or consists of only one value you can also return a value directly:

```lua
ECS.Component.new('position', function(component, x, y)
  return {x, y}
end)

ECS.Component.new('visible', function(component, isVisible)
  return isVisible
end)
```

Lastly you can define components without any data by omitting the function completely. This can be used to tag entities:

```lua
ECS.Component.new('visible')
```

### Entities

Entities are representing your game objects. You can add and remove components entities at any time. 

An entity can only have one instance of a component. Adding the same component again overwrites the existing component

When adding components, the parameters are passed to the function you defined when you created the components (see above).

```lua
-- Create entity
local entity = ECS.Entity.new()
      :add('position', 100, 150)
      :add('velocity', 0, 0)
      :add('size', 10, 10)
      :add('visible')

-- Create entity and add it to a world immediately
local entity = ECS.Entity.new(world)
```

You can clone an existing entity. This is a bit slower than assembling a new one but might be useful in certain cases.

**Note that cloning an entity also creates clones of any entities that you may have stored in its components.**

```lua
-- Clone existing entity
local entity = ECS.Entity.new()
local entityClone = existingEntity:clone()
```

```lua
--- Remove component
entity:remove('size')
```

```lua
-- Get a table of all Components
-- Changing values in the returned tables changes the values in the entity
local components = myEntity:getComponents()

for name, data in pairs(components) do
    -- Do stuff
end
```

```lua
-- Destroy entity immediately and remove it from the world
entity:destroy()
```

```lua
-- Check if an entity has a component
entity:has('position')
-- or multiple components
entity:has({'position', 'velocity'})
```

## Systems

A system represents the actual logic you want to run on entities that have a specific combination of components.

Each system can implement any number of methods (e.g. `update`, `draw`, ...). 

To define which entities a system is interested in, you pass a filter which is a list of component names when creating the system.

### Compact syntax

You can pass the functions you'll need as a table:

```lua
-- Create system 'physics' which processes entities 
-- that have a 'position' and a 'velocity' component
ECS.System.new('physics', {'position', 'velocity'}, {
  update = function(self, entities, dt)
    for _, e in pairs(entities) do
      e.position.x = e.position.x + e.velocity.vx * dt
      e.position.y = e.position.y + e.velocity.vy * dt
    end
  end,
  somethingelse = function(self, entities, dt)
     -- do your thing 
  end
})
```

You can also pass in variables you need in your system:

```lua
ECS.System.new('physics', {'position', 'velocity'}, {
  update = function(self, entities, dt)
    for _, e in pairs(entities) do
      e.velocity.vy = e.velocity.vy + self.gravity
      e.position.x = e.position.x + e.velocity.vx * dt
      e.position.y = e.position.y + e.velocity.vy * dt
    end
  end,
  gravity = 9.81
})
```

### Verbose syntax

`ECS.System.new()` returns the system so you can also add methods and variables the regular way:

```lua
local physicsSystem = ECS.System.new('physics', {'position', 'velocity'})

function physicsSystem:update(entities, dt)
  for _, e in pairs(entities) do
    e.position.x = e.position.x + e.velocity.vx * dt
    e.position.y = e.position.y + e.velocity.vy * dt
  end
  print(self.gravity)
end

physicsSystem.gravity = 9.81
```

## Worlds

For everything to work we create a world and then add systems and entities to it.
To call the functions you defined in the systems you call e.g.`world:call('update')`. All systems that defined an `update()` function will be called with a list of the entities that match their respective filter.

```lua
-- Create a world
local world = ECS.World.new()
```

```lua
-- Add a system to a world
world:addSystem('physics')

-- Remove a system from a world
world:removeSystem('physics')
```

```lua
-- Add an entity to a world
world:addEntity(entity)

-- Remove an entity from a world
world:removeEntity(entity)
```

```lua
-- Call all systems that have an 'update' function
world:call('update', dt)
```

Note that this a very expensive operation as it searches through all entities.

```lua
-- Get all entities that have specific components
local entities = world:getEntities('position')
-- or
local entities = world:getEntities({'position', 'velocity'})
```

## Complete example

```lua
local ECS = require('wacky-ecs.wacky-ecs')
local width, height = love.graphics.getDimensions()

-- Create components for position, velocity, size, color
ECS.Component.new('position', function(component, x, y)
  component.y = y
  component.x = x
end)
ECS.Component.new('velocity', function(component, vx, vy)
  component.vx = vx
  component.vy = vy
end)
ECS.Component.new('size', function(component, w, h)
  component.w = w
  component.h = h
end)
ECS.Component.new('color', function(component, r, g, b, a)
  component.r = r
  component.g = g
  component.b = b
  component.a = a
end)

-- Create physics system
ECS.System.new('physics', {'position', 'velocity'}, {
  update = function(self, entities, dt)
    for _, e in pairs(entities) do
      e.velocity.vy = e.velocity.vy + self.gravity
      e.position.x = e.position.x + e.velocity.vx * dt
      e.position.y = e.position.y + e.velocity.vy * dt
    end
  end,
  gravity = 9.81
})

-- Create system that removes offscreen entities
ECS.System.new('remove_offscreen', {'position', 'size'}, {
  update = function(self, entities, dt)
    for _, e in pairs(entities) do
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
    for _, e in pairs(entities) do
      love.graphics.setColor(e.color.r, e.color.g, e.color.b, e.color.a)
      love.graphics.rectangle('fill',e.position.x, e.position.y, e.size.w, e.size.h)
    end
  end
})

-- Create world
local world = ECS.World.new()
    :addSystem('physics')
    :addSystem('draw_rectangle')
    :addSystem('remove_offscreen')

-- Add 50 entities each frame
function love.update(dt)
  local angle = love.timer.getTime()*10
  local x = width/2 + math.cos(angle) * 100
  local y = height/2 + math.sin(angle) * 100
  for i=50,1,-1 do
    local dir = math.random(0, math.pi * 2 * 100) / 100
    local e = ECS.Entity.new(world)
      :add('position', x, y, math.random(0, math.pi * 2))
      :add('velocity', math.cos(dir) * 200, -400 + math.sin(dir) * 100)
      :add('size', math.random(1, 10), math.random(1, 10))
      :add('color', math.random(), math.random(), math.random(), 1)
  end
  -- Calls the physics:update() and remove_offscreen:update() functions
  world:call('update', dt)
end

function love.draw()
  love.graphics.clear()
  -- Calls the draw_rectangle:draw() function
  world:call('draw')

  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle('fill', 0, 0, 100, 48)
  love.graphics.setColor(0,0,0,1)
  love.graphics.print("Entities: " .. world.entityCount, 1, 0)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 1, 16)
  love.graphics.print("GC: " .. math.floor(collectgarbage("count")/1024) .. "mb", 1, 32)
end
```

<details>
    <summary>Gif of example running</summary>

![Example](https://i.imgur.com/FEAvhP6.gif)

</details>

## License

MIT License - Copyright Felix Dietz (ne0phyte)
