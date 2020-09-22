local PATH = (...):match('(.-)[^%.]+$')
local HashList = require(PATH .. '.util.hashlist')
local ArrayList = require(PATH .. '.util.arraylist')

local Entity, Component, System, World = {}, {}, {}, {}

-- multiple filters per system
-- enable/disable systems?

-- STUFF
local function deepCopy(table)
  local copy = {}
  for k,v in pairs(table) do
    if type(v) == 'table' then v = deepCopy(v) end
    copy[k] = v
  end
  return copy
end

local idCounter = 0
local function getId()
  idCounter = idCounter + 1
  return idCounter
end

-- ENTITY
Entity.__index = Entity
function Entity.new(world)
  if world and getmetatable(world) ~= World then error("Entity.new() - Passed variable is not of type World") end
  local e = setmetatable({ __id = getId() }, Entity)
  if world then world:addEntity(e) end
  return e
end

function Entity:add(component, ...)
  self[component] = Component.__get(component, ...)
  if self.__world then
    self.__world:__updateEntity(self)
  end
  return self
end

function Entity:remove(component)
  self[component] = nil
  if self.__world then
    self.__world:__updateEntity(self)
  end
end

function Entity:has(filter)
  if not filter then return false end
  if type(filter) == 'string' then
    return self[filter] ~= nil
  else
    for _,comp in ipairs(filter) do
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
  if self.__world then self.__world:removeEntity(self) end
end

function Entity:getWorld()
  return self.__world
end

-- COMPONENT
function Component.new(name, initFunc)
  Component[name] = initFunc or 'nil'
end

function Component.__get(name, ...)
  if type(Component[name]) == 'function' then
    return Component[name](...)
  end
  return {}
end

-- SYSTEM
System.__index = System
function System.new(name, filter, events)
  local s = { __filter = filter }
  System[name] = setmetatable(s, System)
  if events then
    for event, func in pairs(events) do
      s[event] = func
    end
  end
  return s
end

function System:getWorld()
  return self.__world
end

function System.__createInstance(name)
  if not System[name] then return nil end
  return setmetatable(deepCopy(System[name]), System)
end

-- WORLD
World.__index = World
function World.new()
  return setmetatable({
    entities = HashList.new(),
    __add = HashList.new(),
    __remove = HashList.new(),
    __update = HashList.new(),
    systems = {},
    entityCount = 0
  }, World)
end

function World:clear(filter)
  if filter then
    local matches = self:getEntities(filter)
    for _,entity in ipairs(matches) do
      self:removeEntity(entity)
    end
  else
    for _, system in pairs(self.systems) do
      system.cache:clear()
    end
    self.entities:clear()
  end
  return self
end

function World:commit()
  for _,entity in ipairs(self.__add) do
    self.entities:add(entity)
    entity.__world = self
    for _,system in pairs(self.systems) do
      if system.system.__filter and entity:has(system.system.__filter) then
        system.cache:add(entity)
        self:__callOwners('wacky_entity_add', entity)
      end
    end
  end
  self.__add:clear()

  for _,entity in ipairs(self.__remove) do
    self.entities:remove(entity)
    entity.__world = nil
    for _,system in pairs(self.systems) do
      system.cache:remove(entity)
      self:__callOwners('wacky_entity_remove', entity)
    end
  end
  self.__remove:clear()

  for _,entity in ipairs(self.__update) do
    for _,system in pairs(self.systems) do
      if entity:has(system.system.__filter) then
        system.cache:add(entity)
      else
        system.cache:remove(entity)
      end
    end
  end
  self.__update:clear()
end

function World:addSystem(name)
  local system = System.__createInstance(name)
  if not system then error("World:addSystem() - System not found: " .. name) end
  system.__world = self
  self.systems[name] = {
    system = system,
    cache = HashList.new(self:getEntities(system.__filter))
  }
  if type(system.wacky_init) == 'function' then
    system:wacky_init(self)
  end
  return self
end

function World:removeSystem(name)
  self.systems[name] = nil
end

function World:getEntityCount()
  return self.entities.size
end

function World:addEntity(entity)
  if not entity then error("World:addEntity() - Entity is nil") end
  self.__add:add(entity, true)
  return self
end

function World:removeEntity(entity)
  if not entity then error("World:removeEntity() - Entity is nil") end
  self.__remove:add(entity, true)
  return self
end

function World:__updateEntity(entity)
  self.__update:add(entity, true)
end

function World:getEntities(filter)
  local matches = {}
  local i = 1
  if not filter then
    for id,entity in pairs(self.entities) do
      matches[i] = entity
      i = i + 1
    end
  else
    for id, entity in ipairs(self.entities) do
      if entity:has(filter) then
        matches[i] = entity
        i = i + 1
      end
    end
  end
  return matches
end

function World:hasSystem(name)
  return self.systems[name] ~= nil
end

function World:getSystem(name)
  if not self.systems[name] then error("World:getSystem() - System not found: " .. name) end
  return self.systems[name].system
end

function World:call(event, ...)
  prof.push(event)
  for _, worldSystem in pairs(self.systems) do
    local system = worldSystem.system
    if type(system[event]) == 'function' then
      prof.push(_)
      system[event](system, worldSystem.cache, ...)
      prof.pop(_)
    end
  end
  prof.pop(event)
end

function World:__callOwners(event, entity)
  for _, worldSystem in pairs(self.systems) do
    local system = worldSystem.system
    if type(system[event]) == 'function' and worldSystem.cache:has(entity) then
      system[event](system, entity)
    end
  end
end

return {
  Entity = Entity,
  Component = Component,
  System = System,
  World = World,
  Data = {
    HashList = HashList,
    ArrayList = ArrayList
  }
}
