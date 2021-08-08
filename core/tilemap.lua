local ECS = require('wacky-ecs.wacky-ecs')

ECS.Component.new('tilemap',
  function()

  end)

local tilemap = ECS.System.new('tilemap', {'tilemap'})

function tilemap:wacky_init(world)
--   self.layers = ECS.Data.ArrayList.new()
  self.layers = {}
  self.tiles = {}
  love.physics.setMeter(32) --the height of a meter our worlds will be 64px
end

function tilemap:load(mapfile)
  local world = self:getWorld()
  local rm = world:getSystem('resource_manager')
  local mapFile = require(mapfile:gsub('.lua', ''):gsub('/', '.'))
  local basePath = mapfile:match('(.*/)')
  self.tiles = {}

  local gid = 1
  for _,tileset in pairs(mapFile.tilesets) do
    tileset.image = basePath .. tileset.image
    gid = self:__loadTileset(tileset, gid)
  end

  for _,layer in pairs(mapFile.layers) do
    if layer.type == 'tilelayer' then
      self.layers[layer.name] = self:__loadTileLayer(layer, world)
    elseif layer.type == 'objectgroup' then
      self:__loadObjectGroupLayer(layer, world)
    end
  end
end


function tilemap:__loadTileset(tileset, gid)
  local rm = self:getWorld():getSystem('resource_manager')
  local tiles = rm:getTiles(tileset.image, tileset.tilewidth, tileset.tileheight)
  -- margin, spacing, transparentcolor
  -- animation, terrain, objectGroup

  for i,quad in ipairs(tiles.quads) do

    local properties, objectGroup
    for _,t in ipairs(tileset.tiles) do
      if t.id == gid-1 then
        properties = t.properties
        objectGroup = t.objectGroup
        break
      end
    end

    self.tiles[gid] = {
      id = gid,
      texture = tiles.texture,
      quad = quad,
      width = tileset.tilewidth,
      height = tileset.tileheight,
      properties = properties or {},
      objectGroup = objectGroup or {}
    }
    gid = gid + 1
  end
  return gid
end

-- function tilemap:__parseProperties(properties)
--   local props = {}
--   for k,v in pairs(properties) do
--     -- TODO dont use loadstring omg
--     props[k] = loadstring('return ' .. v)()
--   end
--   return props
-- end

function tilemap:__loadTileLayer(layer, world)
  local columns = {}
  for y=0,layer.height-1 do
    local row = {}
    for x=0,layer.width-1 do
      local idx = y * layer.width + x
      local tileId = layer.data[idx+1]
      if tileId > 0 and self.tiles[tileId] then
        local tile = self.tiles[tileId]
        local entity = self:__createTile(layer.id, tile, x, y)
        world:addEntity(entity)
        table.insert(row, entity)
      end
    end
    table.insert(columns, row)
  end
  return columns
end

function tilemap:__loadObjectGroupLayer(layer, world)
  if layer.name ~= 'collision' then return end
  local x, y
  for _,o in ipairs(layer.objects) do
    if o.shape == 'polyline' then
      self:__createCollisionBody(o.x, o.y, o.polyline)
    elseif o.shape == 'polygon' then
      self:__createCollisionBody(o.x, o.y, o.polygon)
    end
  end
end

function tilemap:__createCollisionBody(x, y, points)
  local physicsWorld = self:getWorld():getSystem('physics'):getPhysicsWorld()
  local body = love.physics.newBody(physicsWorld, x, y, 'static')

  for i=1,#points-1 do
    local p1 = points[i]
    local p2 = points[i+1]
    local shape = love.physics.newEdgeShape(p1.x, p1.y, p2.x, p2.y)
    love.physics.newFixture(body, shape)
  end
  local p1 = points[#points]
  local p2 = points[1]
  local shape = love.physics.newEdgeShape(p1.x, p1.y, p2.x, p2.y)
  love.physics.newFixture(body, shape)
end

-- function tilemap:__createTile(x, y, w, h, z, texture, quad)
function tilemap:__createTile(id, tile, x, y)
  local w = tile.width
  local h = tile.height
  local x = x * w + w/2
  local y = y * h + h/2

--   local shape = love.physics.new
  local e = ECS.Entity.new()
    :add('position', x, y)
    :add('size', w, h)
    :add('drawable', tile.texture, id, tile.quad)
    :add('suspendable')
    :add('tile')

  local points = nil
  if tile.objectGroup.objects then
    for _,object in ipairs(tile.objectGroup.objects) do
      if object.name == 'collider' then
        points = {}
        if object.shape == "polygon" then
          for _,p in ipairs(object.polygon) do
            table.insert(points, p.x + object.x)
            table.insert(points, p.y + object.y)
          end

        elseif object.shape == "rectangle" then
          points[1] = object.x
          points[2] = object.y
          points[3] = object.x + object.width
          points[4] = object.y
          points[5] = object.x + object.width
          points[6] = object.y + object.height
          points[7] = object.x
          points[8] = object.y + object.height
        end
        break
      end
    end
  end

-- -- Created a separate physics body for every single tile
--   if points then
--     for i=1, #points, 2 do
--       points[i] = points[i] - w/2
--       points[i+1] = points[i+1] - h/2
--     end
--     local physicsWorld = self:getWorld():getSystem('physics'):getPhysicsWorld()
--     local body = love.physics.newBody(physicsWorld, x, y, 'static')
--     local shape = love.physics.newPolygonShape(points)
--     local fixture = love.physics.newFixture(body, shape)
--     e:add('physics', body, shape, fixture)
--   end

  return e
end
