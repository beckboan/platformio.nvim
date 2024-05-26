local package = require("platformio.package")
local boards = require("platformio.boards")

print("Hello from platformio.nvim plugin")

if vim.g.loaded_pio_nvim then
	return
end

-- Define the custom command
vim.api.nvim_create_user_command("PIOSelectBoard", function()
	boards.PIOSelectBoard()
end, { nargs = 0 })

vim.api.nvim_create_user_command("PIOSelectLib", function(opts)
	local name = opts.fargs[1]
	local args = {}
	for i = 2, #opts.fargs do
		table.insert(args, opts.fargs[i])
	end
	package.PIOSelectPkg(name, "library", args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("PIOInstallLib", function(opts)
	local name = opts.fargs[1]
	package.PIOInstallPkg(name, "library")
end, { nargs = 1 })

vim.api.nvim_create_user_command("PIOSelectPlatform", function(opts)
	local name = opts.fargs[1]
	local args = {}
	for i = 2, #opts.fargs do
		table.insert(args, opts.fargs[i])
	end
	package.PIOSelectPkg(name, "platform", args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("PIOInstallPlatform", function(opts)
	local name = opts.fargs[1]
	package.PIOInstallPkg(name, "platform")
end, { nargs = 1 })

vim.api.nvim_create_user_command("PIOSelectTool", function(opts)
	local name = opts.fargs[1]
	local args = {}
	for i = 2, #opts.fargs do
		table.insert(args, opts.fargs[i])
	end
	package.PIOSelectPkg(name, "tool", args)
end, { nargs = "*" })

vim.api.nvim_create_user_command("PIOInstallTool", function(opts)
	local name = opts.fargs[1]
	package.PIOInstallPkg(name, "tool")
end, { nargs = 1 })

vim.g.loaded_pio_nvim = true
