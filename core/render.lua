local ECS = require('wacky-ecs.wacky-ecs')

local Vector = ECS.Data.Vector

ECS.Component.new('drawable',
function(texture, z, quad, color, angle, floor)
  return {
    texture = texture,
    quad = quad or nil,
    color = color or {1,1,1},
    z = z or 0,
    angle = angle or 0,
    floor = floor or true,
    -- scale = Vector.new(1,1) -- TODO remove
  }
end)

local render = ECS.System.new('render', {'position', 'size', 'drawable'})

function render:wacky_init()
  self.drawList = ECS.Data.ArrayList.new(1000)
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

function render:addDrawable(drawable)
  self.drawList:add(drawable)
end

function render:addDrawables(drawables)
  self.drawList:addAll(drawables)
end

local function compareDrawables(e1, e2)
  if e1.drawable.z == e2.drawable.z then return e1.__id < e2.__id
  else return e1.drawable.z < e2.drawable.z end
end

function render:draw(entities)
  local camera = self:getWorld():getSystem('camera')
  local resolveEntityPosition = self.resolveEntityPosition

  -- sort by z and __id
  prof.push('sort_drawables')
  local drawList = self.drawList
  -- remove added drawables that are not visible before sorting
  for i=1,drawList:getHead() do
    local e = drawList[i]
    local x,y = resolveEntityPosition(e)
    if self.enableCulling and not camera:isVisible(x,y,e.size.x,e.size.y) then
      drawList:remove(i)
    end
  end

  for _,e in ipairs(entities) do
    local x,y = resolveEntityPosition(e)
    if not self.enableCulling or camera:isVisible(x,y,e.size.x,e.size.y) then
      drawList:add(e)
    end
  end
  drawList:compact(false, true) --avoid this?

  -- how to sort only range of list with table.sort
  table.sort(drawList, compareDrawables)
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
      if d.quad then
        local qx, qy, qw, qh = d.quad:getViewport( )
        local sx, sy = s.x / qw, s.y / qh
        offx, offy = offx / sx, offy / sy
        love.graphics.draw(d.texture, d.quad, x, y, angle, sx, sy, offx, offy)
      else
        local tw, th = d.texture:getDimensions( )
        local sx, sy = s.x / tw, s.y / th
        offx, offy = offx / sx, offy / sy
        love.graphics.draw(d.texture, x, y, angle, sx, sy, offx, offy)
      end
    else
      -- TODO ??? render with objects rotation
      love.graphics.rectangle('fill', x - s.x/2, y - s.y/2, s.x, s.y)
    end
    -- love.graphics.setColor(0,1,0)
    -- love.graphics.circle('fill', x, y, 1)
  end
  drawList:resetHead()
  prof.pop('render')
end

