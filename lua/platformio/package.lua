local utils = require("platformio.utils")
local commands = require("platformio.commands")

local M = {}

local search_pkg = function(name, args, cmds, page)
	name = name or ""
	args = args or ""
	cmds = cmds or ""
	page = page or 1
	local command = "pkg search '" .. args .. " " .. name .. "' " .. cmds .. " -p " .. page
	local vals = commands.run_pio_command(command)

	if vals == nil or #vals == 0 then
		return {}, 0, 0
	end

	local first_line = vals[1][1]
	local total_packages, current_page, total_pages = first_line:match("Found (%d+) packages %(page (%d+) of (%d+)%)")

	total_packages = tonumber(total_packages)
	current_page = tonumber(current_page)
	total_pages = tonumber(total_pages)

	local packages = {}
	for i = 2, #vals do -- Start from the second entry
		table.insert(packages, vals[i][1])
	end

	return packages, total_packages, total_pages
end

function M.PIOInstallLib(library)
	local name = library
	if library == "" then
		print("Empty library is not accepted")
		return
	end

	if library:match("^#ID:.*") then
		name = library:sub(5)
	end

	local cmd = "pio pkg install -l " .. name

	utils.OpenTerm(cmd)
end

function M.PIOInstallSelect(name, args)
	if name == "" then
		print("Must enter a name")
		return
	end
	args = args or ""
	local bufnr = vim.fn.bufnr("PIO Lib Install")
	local winid = vim.fn.bufwinid(bufnr)
	local height = math.floor(vim.o.lines * 0.5) -- Calculate 50% of the screen height

	if winid ~= -1 then
		vim.api.nvim_set_current_win(winid)
		vim.api.nvim_win_set_height(0, height) -- Set window height
	else
		bufnr = vim.api.nvim_create_buf(false, true)
		local width = vim.o.columns -- Set window width to full screen width

		local opts = {
			relative = "editor",
			width = width,
			height = height,
			row = vim.o.lines - height + 1,
			col = 1,
		}
		local win = vim.api.nvim_open_win(bufnr, true, opts)
		winid = vim.api.nvim_get_current_win()
		if winid < 0 then
			print("Failed to create window")
			return
		end
		vim.api.nvim_win_set_buf(win, bufnr)
		vim.bo.buftype = "nofile"
		vim.bo.bufhidden = "wipe"
		vim.bo.filetype = "piolibs"
		vim.api.nvim_buf_set_name(bufnr, "PIO Lib Install")
		vim.api.nvim_buf_set_keymap(
			bufnr,
			"n",
			"<CR>",
			[[:lua require("platformio.package").PIOInstallLib(vim.fn.getline("."))<CR>]],
			{ noremap = true, silent = true }
		)
	end
	print("Searching Libraries ...")
	local output = vim.fn.systemlist("pio pkg search 'type:library " .. name .. " ' " .. table.concat(args, " "))

	vim.api.nvim_buf_set_option(0, "modifiable", true) -- Make buffer modifiable
	vim.api.nvim_buf_set_lines(0, 0, 0, false, { "Help: Press [Enter] on a library name or ID to install" })

	if #output > 0 then
		-- Append the output of the shell command to the buffer
		vim.api.nvim_buf_set_lines(0, 1, 1, false, output)
	end

	vim.api.nvim_buf_set_option(0, "modifiable", false)
	vim.api.nvim_buf_set_option(0, "readonly", true)
	vim.api.nvim_win_set_cursor(winid, { 1, 0 })
end

return M
