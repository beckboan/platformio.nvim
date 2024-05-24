local package = require("platformio.package")
local boards = require("platformio.boards")

print("Hello from platformio.nvim plugin")

if vim.g.loaded_pio_nvim then
	return
end

-- Define the custom command
vim.api.nvim_create_user_command("PIOBoardSelection", function()
	boards.PIOBoardSelection()
end, { nargs = 0 })

vim.api.nvim_create_user_command("PIOLibrarySelect", function(opts)
	local name = opts.fargs[1]
	local args = {}
	for i = 2, #opts.fargs do
		table.insert(args, opts.fargs[i])
	end
	package.PIOInstallSelect(name, args)
end, { nargs = "*" })

vim.g.loaded_pio_nvim = true
