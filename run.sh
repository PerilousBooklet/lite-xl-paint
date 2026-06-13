#!/bin/bash
lpm run --ephemeral --config='
local core = require "core"
core.reload_module("colors.onedark")
' \
./ onedark paint
