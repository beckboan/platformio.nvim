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
	-- print(first_line)
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

function M.PIOInstallPkg(packname, packtype)
	local prefix = ""
	if packtype == "library" then
		prefix = "-l"
	elseif packtype == "tool" then
		prefix = "-t"
	elseif packtype == "platform" then
		prefix = "-p"
	else
		prefix = ""
	end
	local name = packname

	if name == "" then
		print("Empty package is not accepted")
		return
	end

	if name:match("^#ID:.*") then
		name = name:sub(5)
	end

	local cmd = { "pio", "pkg", "install", prefix, name }

	utils.OpenTerm2(cmd)
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
					-- print(line)
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
			if total_pages == nil then
				callback(all_packages, 0, 0)
				return
			end

			for _, pack in ipairs(packages) do
				table.insert(all_packages, pack)
			end

			if total_pages == 1 then
				callback(all_packages, total_packages, total_pages)
			else
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
			end
		end)
	end)
	coroutine.resume(fetch_packages)
end

function M.PIOSelectPkg(name, packtype, args)
	if name == "" then
		print("Must enter a name")
		return
	end

	args = args or ""
	packtype = packtype or ""

	local winid, bufnr = utils.RunPIOWin("PIO Pkg Install")

	local params = {
		name = name,
		libtype = packtype,
		args = table.concat(args, ""),
		details = true,
		page = 1,
	}

	vim.api.nvim_set_option_value("winhl", "Normal:MyHighlight", { win = winid })
	if winid < 0 then
		print("Failed to create window")
		return
	end

	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })

	vim.api.nvim_buf_set_keymap(
		bufnr,
		"n",
		"<CR>",
		[[:lua require("platformio.package").PIOInstallPkg(vim.fn.getline("."), ']] .. packtype .. [[')<CR>]],
		{ noremap = true, silent = true }
	)

	local prettytype = ""
	if packtype == "library" then
		prettytype = "Libraries"
	elseif packtype == "tool" then
		prettytype = "Tools"
	elseif packtype == "platform" then
		prettytype = "Platforms"
	else
		prettytype = "Packages"
	end

	vim.api.nvim_echo({ { "Searching " .. prettytype .. " ...", "Normal" } }, false, {})

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

		output = utils.remove_consecutive_empty_lines(output)

		vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })

		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
			"Help: Press [Enter] on a " .. packtype .. " name to install",
			"",
			"Found " .. total_packages .. " packages.",
			"",
		})
		vim.api.nvim_buf_set_lines(bufnr, 5, -1, false, output)

		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

		utils.highlight_instructions(bufnr, lines, 4)

		local previous_line_empty = true

		for i = 5, #lines do
			local line = lines[i]
			if previous_line_empty and line ~= "" then
				utils.highlight_line(bufnr, i - 1, line, "^.+$", "PIOLibraryName")
				previous_line_empty = false
			elseif line == "" then
				previous_line_empty = true
			else
				previous_line_empty = false
			end
		end

		vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
		vim.api.nvim_win_set_cursor(winid, { 1, 0 })
	end)
end

return M
