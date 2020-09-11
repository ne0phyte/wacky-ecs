local Entity, Component, System, World = {}, {}, {}, {}

-- add sanity checks!
-- multiple filters per system
-- enable/disable systems?

-- STUFF
function deepCopy(table)
  local copy = {}
  for k,v in pairs(table) do
    if type(v) == 'table' then v = deepCopy(v) end
    copy[k] = v
  end
  return copy
end

local idCounter = 0
function getId()
  idCounter = idCounter + 1
  return idCounter
end

-- ENTITY
Entity.__index = Entity
function Entity.new(world)
  local e = { __id = getId() }
  setmetatable(e, Entity)
  if world then world:addEntity(e) end
  return e
end

function Entity:add(component, ...)
  self[component] = Component.get(component, ...)
  if self.__world ~= nil then
    self.__world:updateEntity(self)
  end
  return self
end

function Entity:remove(component)
  self[component] = nil
  if self.__world ~= nil then
    self.__world:updateEntity(self)
  end
end

function Entity:has(filter)
  if type(filter) == 'string' then
    return self[filter] ~= nil
  else
    for _,comp in pairs(filter) do
      if self[comp] == nil then
        return false
      end
    end
    return true
  end
end

function Entity:getComponents()
  local components = {}
  for k, v in pairs(self) do
    if k:sub(1, 2) ~= '__' then components[k] = v end
  end
  return components
end

function Entity:destroy()
  self.__world:removeEntity(self)
end

function Entity:getWorld()
  return self.__world
end

-- COMPONENT
function Component.new(name, initFunc)
  Component[name] = initFunc
end

function Component.get(name, ...)
  local component = {}
  if type(Component[name]) == 'function' then
    local c = Component[name](component, ...)
    if c ~= nil then
      component = c
    end
  end
  return component
end

-- SYSTEM
System.__index = System
function System.new(name, filter, events)
  local s = { filter = filter }
  setmetatable(s, System)
  System[name] = s
  if events ~= nil then
    for event, func in pairs(events) do
      s[event] = func
    end
  end
  return s
end

function System.createInstance(name)
  return deepCopy(System[name])
end

-- WORLD
World.__index = World
function World.new()
  local w = { entities = {}, systems = {}, entityCount = 0 }
  setmetatable(w, World)
  return w
end

function World:clear(filter)
  if filter then
    local matches = self:getEntities(filter)
    for id,entity in pairs(matches) do
      self:removeEntity(entity)
    end
  else
    for k, system in pairs(self.systems) do
      system.cache = {}
    end
    self.entities = {}
  end
  return self
end

function World:addSystem(name)
  local system = System.createInstance(name)
  self.systems[name] = {
    system = system,
    cache = self:getEntities(system.filter)
  }
  return self
end

function World:addEntity(entity)
  self.entityCount = self.entityCount + 1
  self.entities[entity.__id] = entity
  entity.__world = self
  for _,system in pairs(self.systems) do
    if entity:has(system.system.filter) then
      system.cache[entity.__id] = entity
    end
  end
  return self
end

function World:removeEntity(entity)
  self.entityCount = self.entityCount - 1
  self.entities[entity.__id] = nil
  entity.__world = nil
  for _,system in pairs(self.systems) do
    system.cache[entity.__id] = nil
  end
  return self
end

function World:updateEntity(entity)
  for _,system in pairs(self.systems) do
    if entity:has(system.system.filter) then
      system.cache[entity.__id] = entity
    else
      system.cache[entity.__id] = nil
    end
  end
end

function World:getEntities(filter)
  local matches = {}
  if not filter then
    matches = self.entities
  else
    for _, entity in pairs(self.entities) do
      if entity:has(filter) then
        matches[entity.__id] = entity
      end
    end
  end
  return matches
end

function World:hasSystem(name)
  return self.systems[name] ~= nill
end

function World:getSystem(name)
  return self.systems[name].system
end

function World:call(event, ...)
  for _, system in pairs(self.systems) do
    if system.system[event] then
      system.system[event](system.system, system.cache, ...)
    end
  end
end

return {
  Entity = Entity,
  Component = Component,
  System = System,
  World = World
}
