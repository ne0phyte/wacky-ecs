local ECS = require('wacky-ecs.wacky-ecs')

ECS.System.new('mouse_camera_pan', nil, {
  dragStart = {x = 0, y = 0},
  cameraStart = {x = 0, y = 0},
  dragging = false,
  update = function(self, events, dt)
    local world = self:getWorld()
    local input = world:getSystem('input')
    local camera = world:getSystem('camera')
    local mDown = input:getMouseButton(2)
    local x, y = input:getMouse()
    local w,h = camera:getScreen()

--     local wx, wy = input:getMouseWheel()
--     wy = math.min(wy, 9)
--     camera:setZoom((10-wy)/10, (10-wy)/10)
    if mDown then
      if not self.dragging then
        local cx, cy = camera:getPosition()
        self.dragStart.x = x
        self.dragStart.y = y
        self.cameraStart.x = cx
        self.cameraStart.y = cy
        self.dragging = true
      end
    else
      self.dragging = false
    end

    if self.dragging then
      local dx = self.dragStart.x - x
      local dy = self.dragStart.y - y
      local gx, gy = camera:screenToGameOrigin(dx, dy)
      camera:setPosition(self.cameraStart.x - gx, self.cameraStart.y - gy)
    end
  end
})
