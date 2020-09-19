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
ECS.Component.new('position', function(x, y)
  return { x = x, y = y }
end)
```

If your component doesn't need named table fields or consists of only one value you can also return a value directly:

```lua
ECS.Component.new('position', function(x, y)
  return {x, y}
end)

ECS.Component.new('visible', function(isVisible)
  return isVisible
end)
```

Lastly you can define components without any data by omitting the function completely. This can be used to tag entities:

```lua
ECS.Component.new('visible')
```

### Entities

Entities are representing your game objects and consist of components. You can add and remove components at any time.

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

```lua
-- Get world the entity is in
local entityWorld = entity:getWorld()
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

You can get a reference to the world inside systems by calling `self:getWorld()`.

### Verbose syntax

`ECS.System.new()` returns the system so you can also add methods and variables like this:

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

-- Commit changed entities (add/remove/change) from last update
world:commit()
```

```lua
-- Remove all entities from world
world:clear()
-- or selectively
world:clear('position')
world:clear({'position', 'velocity'})
```

To call the functions you defined in the systems you call e.g.`world:call('update')`. All systems that defined an `update()` function will be called with a list of the entities that match their respective filter. Any additional parameters are passed to the function.

```lua
-- Call all systems that have an 'update' function
world:call('update', dt)
-- pass additional parameters
world:call('update', dt, 42, true)
```

```lua
-- Get all entities that have specific components
-- Note that this a very expensive operation as
-- it searches through all entities and creates a new table
local entities = world:getEntities('position')
-- or
local entities = world:getEntities({'position', 'velocity'})
```

```lua
-- Check if world contains system
local hasPhysics = world:hasSystem('physics')

-- Get system from world
local physicsSystem = world:getSystem('physics')
```

## Complete example

```lua
local ECS = require('wacky-ecs.wacky-ecs')
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

-- Add 100 entities each frame
function love.update(dt)
  stats.update = love.timer.getTime()
  local angle = love.timer.getTime()*10
  local x = width/2 + math.cos(angle) * 100
  local y = height/2 + math.sin(angle) * 100
  for i=100,1,-1 do
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
```

<details>
    <summary>Gif of example running</summary>

![Example](https://i.imgur.com/FEAvhP6.gif)

</details>

## License

MIT License - Copyright Felix Dietz (ne0phyte)
