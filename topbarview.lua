local core = require "core"
local common = require "core.common"
local config = require "core.config"
local command = require "core.command"
local style = require "core.style"

local View = require "core.view"

-- TODO: change color of icons when cursor is hovering above them

-- TODO: contextmenu: button to clean whole view

-- FIX: draw top black line only beneath tab title rectangle

-- FUTURE_TODO: use the new Canvas by Guldoman

local TopbarView = View:extend()

function TopbarView:new(paint_view)
	TopbarView.super.new(self)
  self.paint_view = paint_view

	self.topbar_font = nil
	for _, dir in ipairs({ USERDIR .. "/plugins/paint/font/paint.ttf" }) do
		core.try(function()
		  -- FIX: icons are not centered in topbar
		  self.topbar_font = renderer.font.load(
		  	dir,
		  	23 * SCALE,
		  	{
		  		antialiasing = "grayscale",
		  		hinting = "full",
		  		bold = false,
		  		italic = false,
		  		underline = false,
		  		smoothing = false,
		  		strikethrough = false
		  	}
		  )
    end)
	end

	self.visible = true
	self.size.x = 32 * 1.1 * SCALE
	self.size.y = 25 * 1.6 * SCALE

	self.colors = {
		default = { name = "Default", color = style.syntax["normal"]   },
		blue =    { name = "Blue",    color = style.syntax["function"] },
		red =     { name = "Red",     color = style.syntax["keyword2"] },
		purple =  { name = "Purple",  color = style.syntax["keyword"]  },
		orange =  { name = "Orange",  color = style.syntax["number"]   },
		yellow =  { name = "Yellow",  color = style.syntax["literal"]  },
		green =   { name = "Green",   color = style.syntax["string"]   },
		gray =    { name = "Gray",    color = style.syntax["comment"]  },
	}

	self.topbar_items = {}
	-- TODO: show pencil as selected by default
	self.tool_items = {
		{ symbol = utf8.char(59394),  command = "",   text = "Save"      },
		{ symbol = utf8.char(59397),  command = "",   text = "Undo"      },
		{ symbol = utf8.char(59396),  command = "",   text = "Redo"      },
		{ symbol = utf8.char(59393),  command = "",   text = "Pencil"    },
		{ symbol = utf8.char(61741),  command = "",   text = "Eraser"    },
		{ symbol = utf8.char(),       command = "",   text = "Separator" },
	}
	self.color_items = {
		{
			symbol = utf8.char(60069),
			color = self.colors.default.color,
			command = "Color: " .. self.colors.default.name,
			action = function()
				config.plugins.paint.draw_color = self.colors.default.color
			end
		},
		{
			symbol = utf8.char(60069),
			color = self.colors.blue.color,
			command = "Color: " .. self.colors.blue.name,
			action = function()
				config.plugins.paint.draw_color = self.colors.blue.color
			end
		},
		{
			symbol = utf8.char(60069),
			color = self.colors.red.color,
			command = "Color: " .. self.colors.red.name,
			action = function()
				config.plugins.paint.draw_color = self.colors.red.color
			end
		},
		{
			symbol = utf8.char(60069),
			color = self.colors.purple.color,
			command = "Color: " .. self.colors.purple.name,
			action = function()
				config.plugins.paint.draw_color = self.colors.purple.color
			end
		},
		{
			symbol = utf8.char(60069),
			color = self.colors.orange.color,
			command = "Color: " .. self.colors.orange.name,
			action = function()
				config.plugins.paint.draw_color = self.colors.orange.color
			end
		},
		{
			symbol = utf8.char(60069),
			color = self.colors.yellow.color,
			command = "Color: " .. self.colors.yellow.name,
			action = function()
				config.plugins.paint.draw_color = self.colors.yellow.color
			end
		},
		{
			symbol = utf8.char(60069),
			color = self.colors.green.color,
			command = "Color: " .. self.colors.green.name,
			action = function()
				config.plugins.paint.draw_color = self.colors.green.color
			end
		},
		{
			symbol = utf8.char(60069),
			color = self.colors.gray.color,
			command = "Color: " .. self.colors.gray.name,
			action = function()
				config.plugins.paint.draw_color = self.colors.gray.color
			end
		},
	}
	table.move(self.tool_items, 1, #self.tool_items, #self.topbar_items + 1, self.topbar_items)
	table.move(self.color_items, 1, #self.color_items, #self.topbar_items + 1, self.topbar_items)

	-- NOTE: position of default color is hard-coded
	self.active_color = self.color_items[1]
end

function TopbarView:get_icon_width()
	local max_dim = 0
	for _,v in ipairs(self.topbar_items) do
	  max_dim = math.max(max_dim, self.topbar_font:get_width(v.symbol))
	end

	return max_dim
end

function TopbarView:each_item()
	local icon_h, icon_w = self.topbar_font:get_height(), self:get_icon_width()
	local topbar_spacing = icon_h / 3
	local ox, oy = self:get_content_offset()
	local index = 0

	local iter = function()
		index = index + 1
		if index <= #self.topbar_items then
			local dx, dy

				dx = style.padding.x + (icon_w + topbar_spacing) * (index - 1)
				dy = style.padding.y

				if dx + icon_w > self.size.x then return end
			return self.topbar_items[index], ox + dx, oy + dy, icon_w, icon_h
		end
	end

	return iter
end

local function draw_selection_outline(x, y, w, h)
	renderer.draw_rect(x, y, w, 2, style.syntax["text"])
	renderer.draw_rect( x, y + h - 2, w, 2, style.syntax["text"])
	renderer.draw_rect(x, y, 2, h, style.syntax["text"])
	renderer.draw_rect( x + w - 2, y, 2, h, style.syntax["text"])
end

function TopbarView:draw()
	if not self.visible then return end

	self:draw_background(style.background)

	-- Icons
	for item, x, y, w, h in self:each_item() do
		local color = item == self.hovered_item and command.is_valid(item.command) and style.text or style.dim
		if item.color then
			-- Draw the colored square button
			renderer.draw_rect(x + 2, y + 2, w - 4, h - 4, item.color)
			-- Show current color selection
      if item == self.active_color then
      	draw_selection_outline(x, y, w, h)
      end
			-- ?
			if item == self.hovered_item then
				draw_selection_outline(x, y, w, h)
			end
		else
			common.draw_text(self.topbar_font, color, item.symbol, nil, x, y, w, h)
		end
	end

	-- WIP: Top line
  local tab_x = self.position.x
  local tab_w = 0
  local node = core.root_view.root_node:get_node_for_view(self.paint_view)
  if node then
    -- We must subtract tab_offset in case the user has many tabs and the bar is scrolled
    tab_x = node.position.x - (node.tab_offset or 0)
    for _, view in ipairs(node.views) do
      local w = 0
      if node.get_tab_width then
        w = node:get_tab_width(view)
      else
        -- Fallback: Use a wider padding multiplier (4x) to account for all sides
        local icon_w = style.icon_font:get_width("x")
        local text_w = style.font:get_width(view:get_name())
        -- FIX: style.padding.x should be increased by ?
        w = icon_w + text_w + (style.padding.x)
      end
      if view == self.paint_view then
        tab_w = w
        break
      end
      tab_x = tab_x + w
    end
  end
  renderer.draw_rect(
    tab_x,
    self.position.y,
    tab_w,
    1,
    { 0, 0, 0, 255 }
  )

	-- Bottom line
	renderer.draw_rect(
		self.position.x,
		self.position.y + self.size.y - 1,
		self.size.x,
		1,
		{ 0, 0, 0, 255 }
	)
end

function TopbarView:on_mouse_pressed(button, x, y, clicks)
	if not self.visible then return end

  -- If the click is below the topbarview's height, ignore it
	if y > self.position.y + self.size.y then return false end

	local caught = TopbarView.super.on_mouse_pressed(self, button, x, y, clicks)
	if caught then return caught end

	if core.last_active_view then
		core.set_active_view(core.last_active_view)
	end

	if self.hovered_item then
		if self.hovered_item.action then
        -- Change color
        self.hovered_item.action()
        -- Change current color selection
        if self.hovered_item.color then
        	self.active_color = self.hovered_item
        end
    elseif command.is_valid(self.hovered_item.command) then
        command.perform(self.hovered_item.command)
    end
	end

	return true
end


function TopbarView:on_mouse_moved(px, py, ...)
	if not self.visible then return end

	TopbarView.super.on_mouse_moved(self, px, py, ...)
	self.hovered_item = nil

	local x_min, x_max, y_min, y_max = self.size.x, 0, self.size.y, 0
	for item, x, y, w, h in self:each_item() do
		x_min, x_max = math.min(x, x_min), math.max(x + w, x_max)
		y_min, y_max = y, y + h

		if px > x and py > y and px <= x + w and py <= y + h then
			self.hovered_item = item
			core.status_view:show_tooltip(command.prettify_name(item.command))
			self.tooltip = true
			return
		end
	end

	if self.tooltip and not (px > x_min and px <= x_max and py > y_min and py <= y_max) then
		core.status_view:remove_tooltip()
		self.tooltip = false
	end
end

return TopbarView
