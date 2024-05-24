local M = {}

print("Hello from platformio.nvim plugin")
local pio = require("platformio.init")

if vim.g.loaded_pio_nvim then
	return
end

vim.g.loaded_pio_nvim = true
