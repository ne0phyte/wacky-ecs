local ECS = require('wacky-ecs.wacky-ecs')

local Vector2D = ECS.Data.Vector2D

ECS.Component.new('drawable',
function(texture, z, quad, color, angle, floor)
  return {
    texture = texture,
    quad = quad or nil,
    color = color or {1,1,1},
    z = z or 0,
    angle = angle or 0,
    floor = floor or true,
    scale = Vector2D(1,1)
  }
end)

local render = ECS.System.new('render', {'position', 'size', 'drawable'})

function render:wacky_init()
  self.drawList = ECS.Data.ArrayList.new(10000)
  self.drawListLength = 0
  self.renderCount = 0
  self.enableCulling = true
end

function render.resolveEntityPosition(entity)
  if not entity.parent then
    return entity.position.x, entity.position.y
  end
  local px, py = render.resolveEntityPosition(entity.parent)
  return entity.position.x + px, entity.position.y + py
end

function render:getRenderCount()
  return self.drawListLength
end

function render:draw(entities)
  local camera = self:getWorld():getSystem('camera')
  local resolveEntityPosition = self.resolveEntityPosition

  -- sort by z and __id
  prof.push('sort_drawables')
  local drawList = self.drawList
  drawList:resetHead()
  for _,e in ipairs(entities) do
    local x,y = resolveEntityPosition(e)
    if not self.enableCulling or camera:isVisible(x,y,e.size.x,e.size.y) then
      drawList:add(e)
    end
  end
  drawList:resize() -- avoid?
  -- how to sort only range of list with table.sort
  table.sort(drawList, function(e1, e2)
    if e1.drawable.z == e2.drawable.z then return e1.__id < e2.__id
    else return e1.drawable.z < e2.drawable.z end
  end)
  self.drawListLength = drawList:getHead()
  prof.pop('sort_drawables')

  prof.push('render')
  for _,e in ipairs(drawList) do
    local d = e.drawable
    local p = e.position
    local s = e.size

    local x,y = resolveEntityPosition(e)
    local offx,offy = e.size.x/2, e.size.y/2
    local angle = e.angle or 0 + d.angle

    if d.floor then
      x = math.floor(0.5+x)
      y = math.floor(0.5+y)
    end
    if e.color then
      love.graphics.setColor(e.color)
    else
      love.graphics.setColor(1,1,1)
    end
    if d.texture then
      x,y = x+offx, y+offy
      if d.quad then
        local qx, qy, qw, qh = d.quad:getViewport( )
        local sx, sy = s.x / qw, s.y / qh
        sx, sy = sx * d.scale.x, sy * d.scale.y
        love.graphics.draw(d.texture, d.quad, x, y, angle, sx, sy, offx, offy)
      else
        local tw, th = d.texture:getDimensions( )
        local sx, sy = s.x / tw, s.y / th
        sx, sy = sx * d.scale.x, sy * d.scale.y
        love.graphics.draw(d.texture, x, y, angle, sx, sy, offx, offy)
      end
    else
      love.graphics.rectangle('fill', x, y, s.w, s.h)
    end
  end
  prof.pop('render')
end

