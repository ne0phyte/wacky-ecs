local ECS = require('wacky-ecs.wacky-ecs')

local resourceManager = ECS.System.new('resource_manager', nil)

resourceManager.textures = {}
resourceManager.tilesets = {}

function resourceManager:getTexture(file)
  if not self.textures[file] then
    self.textures[file] = love.graphics.newImage(file)
  end
  return self.textures[file]
end

function resourceManager:getTiles(file, width, height)
  if not self.tilesets[file] then
    local tmp = {
      quads = {},
      texture = self:getTexture(file),
      width = width,
      height = height
    }
    local tw, th = tmp.texture:getDimensions()
    for y=0,th-height,height do
      for x=0,tw-width,width do
        table.insert(tmp.quads, love.graphics.newQuad(x, y, width, height, tw, th))
      end
    end
    self.tilesets[file] = tmp
  end
  return self.tilesets[file]
end
