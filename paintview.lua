local core = require "core"
local config = require "core.config"
local style = require "core.style"

local View = require "core.view"
local TopbarView = require "plugins.paint.topbarview"

-- WIP: save system
-- TODO: add command to list all paint sessions (globally) and all paint sessions for current project
-- TODO: add command to create new paint session

-- TODO: history system for full (!) undo/redo
-- TODO: erase drawn points

-- TODO: make PaintView scrollable (vert and horiz)

-- TODO: REFACTOR: use common.lerp() instead of reinventing the wheel

-- FUTURE_TODO: use the new Canvas by Guldoman

local PaintView = View:extend()

function PaintView:new()
  PaintView.super.new(self)
  self.points = {}
  self.last_point = nil
  self.is_drawing = false

  self.is_pencil_selected = true
  self.is_eraser_selected = false

  -- WIP: shapes
  self.is_shape_square_selected = false
  self.is_shape_circle_selected = false

  self.topbar = TopbarView(self)
end

function PaintView:get_name()
  return "Paint"
end

function PaintView:update()
  PaintView.super.update(self)

  self.topbar.position.x = self.position.x
  self.topbar.position.y = self.position.y
  self.topbar.size.x = self.size.x
  self.topbar:update()
end

function PaintView:draw()
  -- Draw background
  self:draw_background(config.plugins.paint.background_color)

  -- Init
  local conf = config.plugins.paint
  local x_pos, y_pos = self.position.x, self.position.y
  local x_size, y_size = self.size.x, self.size.y
  local point_size = conf.point_size

  -- Draw user input
  for _, point in ipairs(self.points) do
    if point.x and point.y then
      renderer.draw_rect(
        point.x,
        point.y,
        point_size,
        point_size,
        point.color
      )
    end
  end

  self.topbar:draw()
end

function PaintView:add_snapped_point(x, y)
  local point_size = config.plugins.paint.point_size

  local snapped_x = math.floor(x / point_size) * point_size
  local snapped_y = math.floor(y / point_size) * point_size

  if self.last_point and self.last_point.x == snapped_x and self.last_point.y == snapped_y then
    return
  end

  local new_point = {
    x = snapped_x,
    y = snapped_y,
    color = config.plugins.paint.draw_color or style.text
  }
  table.insert(self.points, new_point)
  self.last_point = new_point
end

function PaintView:draw_line_to(x, y)
  if not self.last_point then
    self:add_snapped_point(x, y)
    return
  end

  -- Init
  local point_size = config.plugins.paint.point_size
  local x1, y1 = self.last_point.x, self.last_point.y

  -- Target snapped coordinates
  local x2 = math.floor(x / point_size) * point_size
  local y2 = math.floor(y / point_size) * point_size

  local dx = x2 - x1
  local dy = y2 - y1
  local distance = math.sqrt(dx * dx + dy * dy)

  -- If the mouse hasn't moved past a full point_size step, don't draw anything yet
  if distance < point_size then return end

  -- Calculate how many blocks fit in the gap
  local steps = math.floor(distance / point_size)

  -- Linearly interpolate (LERP) and stamp down adjacent blocks
  for i = 1, steps do
    local t = i / steps
    local curr_x = x1 + (dx * t)
    local curr_y = y1 + (dy * t)
    self:add_snapped_point(curr_x, curr_y)
  end
end

function PaintView:on_mouse_pressed(button, x, y, ...)
  if self.topbar:on_mouse_pressed(button, x, y, ...) then
    return true
  end

  local caught = PaintView.super.on_mouse_pressed(self, button, x, y)
  if caught then return true end

  -- Prevent drawing inside the toolbar's bounds
  if y <= self.position.y + self.topbar.size.y then
    return
  end

  if button == "left" then
    self.is_drawing = true
    self.last_point = nil
    self:draw_line_to(x, y)
    -- WIP: save data
    return true
  end
end

function PaintView:on_mouse_moved(x, y, dx, dy, ...)
  if self.topbar:on_mouse_moved(x, y, dx, dy, ...) then
    return true
  end

  local caught = PaintView.super.on_mouse_moved(self, x, y, dx, dy)
  if caught then return true end

  if self.is_drawing then
    -- Stop drawing strokes if the mouse moves up into the toolbar region
    if y <= self.position.y + self.topbar.size.y then 
      self.last_point = nil
      return true
    end
    self:draw_line_to(x, y)
    -- WIP: save data
    return true
  end
end

function PaintView:on_mouse_released(button, x, y, ...)
  if self.topbar:on_mouse_released(button, x, y) then
    return true
  end

  local caught = PaintView.super.on_mouse_released(self, button, x, y)
  if caught then return true end

  if button == "left" then
    self.is_drawing = false
    return true
  end
end

return PaintView
