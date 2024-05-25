local utils = require("platformio.utils")
local commands = require("platformio.commands")

local M = {}

local search_pkg = function(opts)
	-- Opts are name, type, args, and page
	opts = opts or {}
	local name = opts["name"] or ""
	local args = opts["args"] or {}
	local page = opts["page"] or 1
	local details = opts["details"] or false

	local libtype = ""
	if opts["libtype"] then
		libtype = "type:" .. opts["libtype"]
	end

	local command = "pkg search '" .. libtype .. " " .. name .. "' " .. args .. "-p " .. page
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

	if details == false then
		for i = 2, #vals do -- Start from the second entry
			table.insert(packages, vals[i][1])
		end
	else
		for i = 2, #vals do
			for line in vals[i] do
				table.insert(packages, line)
			end
		end
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

local search_pkg_async = function(opts, callback)
	opts = opts or {}
	local name = opts["name"] or ""
	local args = opts["args"] or ""
	local page = opts["page"] or 1
	local details = opts["details"] or false

	local libtype = ""
	if opts["libtype"] then
		libtype = "type:" .. opts["libtype"]
	end

	local command = "pkg search '" .. libtype .. " " .. name .. "' " .. args .. "-p " .. page
	-- print(command)

	commands.run_pio_command_async(command, function(vals)
		if not vals or #vals == 0 then
			callback({}, 0, 0)
			return
		end

		local first_line = vals[1][1]
		local total_packages, current_page, total_pages =
			first_line:match("Found (%d+) packages %(page (%d+) of (%d+)%)")

		total_packages = tonumber(total_packages)
		current_page = tonumber(current_page)
		total_pages = tonumber(total_pages)

		local packages = {}

		if details == false then
			for i = 2, #vals do
				-- print(vals[i][1])
				table.insert(packages, vals[i][1])
			end
		else
			for i = 2, #vals do
				for _, line in ipairs(vals[i]) do
					table.insert(packages, line)
					print(line)
				end
				table.insert(packages, "")
			end
		end

		callback(packages, total_packages, total_pages)
	end)
end

local function async_pio_pkg_search(params, callback)
	local all_packages = {}
	local total_packages
	local total_pages

	local fetch_packages = coroutine.create(function()
		-- Fetch packages for the first page
		search_pkg_async(params, function(packages, total_packs, pages)
			total_packages = total_packs
			total_pages = pages

			for _, pack in ipairs(packages) do
				table.insert(all_packages, pack)
			end

			for page = 2, total_pages do
				params.page = page -- Increment the page number
				search_pkg_async(params, function(packages_page)
					-- Append packages for the current page
					for _, pack in ipairs(packages_page) do
						table.insert(all_packages, pack)
					end

					if #all_packages >= total_packages then
						callback(all_packages, total_packages, total_pages)
					end
				end)
			end
		end)
	end)
	coroutine.resume(fetch_packages)
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

	local params = {
		name = name,
		libtype = "library",
		args = table.concat(args, ""),
		details = true,
		page = 1,
	}

	async_pio_pkg_search(params, function(packages, total_packages)
		local output = {}
		if total_packages == 0 then
			output = { "No packages found" }
		else
			for _, package in ipairs(packages) do
				local processed_package = package:gsub("[\r\n]+", "")
				table.insert(output, processed_package)
			end
		end
		vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
		vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })

		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
			"Help: Press [Enter] on a library name or ID to install",
			"",
			"Found " .. total_packages .. " packages.",
			"",
		})
		vim.api.nvim_buf_set_lines(bufnr, 5, -1, false, output)
		vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
		vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
		vim.api.nvim_win_set_cursor(winid, { 1, 0 })
	end)
end

return M
