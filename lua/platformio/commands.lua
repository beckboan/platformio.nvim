local M = {}

function M.PIOCommandList(args, L, P)
	local commands = {
		access = { "grant", "list", "private", "public", "revoke", "-h" },
		account = { "destroy", "forgot", "login", "logout", "password", "register", "show", "token", "update", "-h" },
		boards = { "--installed", "--json-output", "-h" },
		check = {
			"--environment",
			"--project-dir",
			"--project-conf",
			"--pattern",
			"--flags",
			"--severity",
			"--silent",
			"--json-output",
			"--fail-on-defect",
			"--skip-packages",
			"-h",
		},
		ci = {
			"--lib",
			"--exclude",
			"--board",
			"--build-dir",
			"--keep-build-dir",
			"--project-conf",
			"project-option",
			"--verbose",
			"--help",
		},
		debug = { "--project-dir", "--project-conf", "--environment", "--load-mode", "--verbose", "--interface", "-h" },
		device = { "list", "monitor", "-h" },
		home = { "--port", "--host", "--no-open", "--shutdown-timeout", "--session-id", "-h" },
		lib = { "builtin", "install", "list", "register", "search", "show", "stats", "uninstall", "update" },
		pkg = {
			"exec",
			"install",
			"list",
			"outdated",
			"pack",
			"publish",
			"search",
			"show",
			"stats",
			"uninstall",
			"unpublish",
			"update",
		},
		org = { "add", "create", "destroy", "list", "remove", "update", "-h" },
		package = { "pack", "publish", "unpublish", "-h" },
		platform = { "frameworks", "install", "list", "search", "show", "uninstall", "update", "-h" },
		project = { "config", "data", "init", "-h" },
		remote = { "agent", "device", "run", "test", "update", "-h" },
		run = {
			"--environment",
			"--target",
			"--upload-port",
			"--project-dir",
			"--project-conf",
			"--jobs",
			"--silent",
			"--verbose",
			"--disable-auto-clean",
			"--list-targets",
			"-h",
		},
		settings = { "get", "reset", "set", "-h" },
		team = { "add", "create", "destroy", "list", "remove", "update", "-h" },
		test = {
			"-e",
			"-f",
			"-i",
			"--upload-port",
			"-d",
			"-c",
			"--without-building",
			"--without-uploading",
			"--without-testing",
			"--no-reset",
			"--monitor-rts",
			"--monitor-dtr",
			"-v",
			"-h",
		},
		update = { "--core-packages", "--only-check", "--dry-run", "-h" },
		upgrade = {},
	}
	if string.match(L, "^PIO *[^ ]*$") then
		return table.concat(vim.tbl_keys(commands), "\n")
	elseif string.match(L, "^PIO *[^ ]* *.*$") then
		local name = string.match(L, "^PIO *([^ ]*) *.*$")
		if name and commands[name] then
			return table.concat(commands[name], "\n")
		end
	end
	return ""
end

function M.PIOKeywordList()
	local commands = {
		"keyword:",
		"header:",
		"framework:",
		"platform:",
		"author:",
		"id:",
	}
	return table.concat(commands, "\n")
end
function M.PIOGetIniKeywords()
	local commands = {}
	local pio_ini = io.open("platformio.ini", "r")
	if pio_ini then
		for line in pio_ini:lines() do
			if string.match(line, "^platform[%s\t]*=.*") then
				local pltf = string.gsub(line, "=", ":", "g")
				pltf = string.gsub(pltf, "[%s\t]", "", "g")
				table.insert(commands, pltf)
			end
			if string.match(line, "^framework[%s\t]*=.*") then
				local pltf = string.gsub(line, "=", ":", "g")
				pltf = string.gsub(pltf, "[%s\t]", "", "g")
				table.insert(commands, pltf)
			end
		end
		pio_ini:close()
	end
	return commands
end

M.parse_command = function(output)
	local data = {}
	local current_group = {}
	local empty_line_count = 0

	if output == nil then
		return
	end

	local output_string = ""
	if type(output) == "string" then
		output_string = output
	elseif type(output) == "table" then
		output_string = table.concat(output, "\n")
	else
		-- TODO: Need to log here
	end

	for line in output_string:gmatch("([^\r\n]*[\r\n]?)") do
		-- print(line)
		if line == "\n" or line == "\r\n" then
			empty_line_count = empty_line_count + 1
		else
			if empty_line_count > 0 then
				table.insert(data, current_group)
				current_group = {} -- Reset the current group for the next set of lines
				empty_line_count = 0 -- Reset the empty line count
			end
			table.insert(current_group, line)
		end
	end

	-- Add the last group to the data table
	if #current_group > 0 then
		table.insert(data, current_group)
	end

	return data
end

M.run_pio_command_async = function(command, callback)
	local full_command = "pio " .. command

	vim.fn.jobstart(full_command, {
		on_stdout = function(_, data, _)
			if data then
				local output = table.concat(data, "\n")

				local lines = M.parse_command(output)
				callback(lines)
			end
		end,
		stdout_buffered = true,
	})
end
return M
