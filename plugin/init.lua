local boards = require("platformio.boards")

print("Hello from platformio.nvim plugin")

if vim.g.loaded_pio_nvim then
	return
end

-- Define the custom command
vim.api.nvim_create_user_command("PIOBoardSelection", function()
	boards.PIOBoardSelection()
end, { nargs = 0 })

vim.g.loaded_pio_nvim = true
