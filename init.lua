--mod-version:3
local core = require "core"
local config = require "core.config"
local common = require "core.common"
local command = require "core.command"
local keymap = require "core.keymap"
local style = require "core.style"

local PaintView = require "plugins.paint.paintview"

config.plugins.paint = common.merge({
  background_color = style.background,
  draw_color = style.text,
  point_size = 1
}, config.plugins.paint)


-----------------
-- Save System --
-----------------

local function check_save_data()
	-- TODO: check if save data file exists (if not : create it)
	-- TODO: load save data
	-- TODO: check if current project contains an entry (if not: add it)
end


--------------
-- Commands --
--------------

command.add(nil, {
  ["paint:new-canvas"] = function()
    local root_node = core.root_view:get_active_node()
    local paint_view = PaintView()
    root_node:add_view(paint_view)
  end
})

-- TODO: Save current session
-- TODO: map this command to the topbar's save button
command.add(
  -- TODO: check if focus is inside a PaintView
  nil,
  {
    -- TODO: save current PaintView data to new/existing entry in save-data file in USERDIR
  }
)

------------
-- Keymap --
------------

keymap.add({ ["alt+z"] = "paint:new-canvas" })


----------
-- Init --
----------

core.add_thread(function() check_save_data() end)
