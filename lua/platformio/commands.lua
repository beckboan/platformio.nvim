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
			"install", -- done
			"list",
			"outdated",
			"show",
			"uninstall",
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

-- Parse the 'pkg list' command output
M.parse_pkg_list = function(output)
	local environments = {}
	local libraries = {}
	local current_env = nil
	local inside_libraries_section = false

	if output == nil then
		return { libraries = {}, environments = {} }
	end

	local output_string = type(output) == "table" and table.concat(output, "\n") or output

	for line in output_string:gmatch("[^\r\n]+") do
		line = vim.trim(line)

		-- Detect environment sections
		if line:match("^Resolving") then
			-- Match the next word after 'Resolving' as the environment name
			current_env = line:match("^Resolving ([^ ]+)")
			if current_env then
				environments[current_env] = {}
				inside_libraries_section = false
			end
		elseif line:match("^Libraries") then
			inside_libraries_section = true
		elseif line:match("^└──") and inside_libraries_section then
			local library_name = line:match("└── ([^@]+) @")
			if library_name then
				if not libraries[library_name] then
					libraries[library_name] = true
				end
				if current_env then
					table.insert(environments[current_env], library_name)
				end
			end
		end
	end

	local libraries = vim.tbl_keys(libraries)

	return { libraries = libraries, environments = environments }
end

-- Default parsing for other commands
M.parse_default = function(output)
	local data = {}
	local current_group = {}
	local empty_line_count = 0

	local output_string = type(output) == "table" and table.concat(output, "\n") or output

	for line in output_string:gmatch("([^\r\n]*[\r\n]?)") do
		if line == "\n" or line == "\r\n" then
			empty_line_count = empty_line_count + 1
		else
			if empty_line_count > 0 then
				table.insert(data, current_group)
				current_group = {}
				empty_line_count = 0
			end
			table.insert(current_group, line)
		end
	end

	if #current_group > 0 then
		table.insert(data, current_group)
	end

	return data
end

-- General command output parsing function
M.parse_command_output = function(command, output)
	if command == "pkg list" then
		return M.parse_pkg_list(output)
	else
		-- Default parsing or error handling
		return M.parse_default(output)
	end
end

M.run_pio_command_async = function(command, callback)
	local full_command = "pio " .. command

	-- Echo the full command to the Neovim CLI
	vim.api.nvim_echo({ { "Running command: " .. full_command, "Normal" } }, false, {})

	vim.fn.jobstart(full_command, {
		on_stdout = function(_, data, _)
			if data then
				local output = table.concat(data, "\n")
				local parsed_output = M.parse_command_output(command, output)
				callback(parsed_output)
			else
				vim.api.nvim_echo({ { "No data returned from command", "ErrorMsg" } }, false, {})
			end
		end,
		on_stderr = function(_, data, _)
			if data then
				-- vim.api.nvim_echo({ { "Command error: " .. output, "ErrorMsg" } }, false, {})
			else
				vim.api.nvim_echo({ { "No error data returned from command", "ErrorMsg" } }, false, {})
			end
		end,
		on_exit = function(_, code, _)
			if code ~= 0 then
				vim.api.nvim_echo({ { "Command exited with error code: " .. code, "ErrorMsg" } }, false, {})
			end
		end,
		stdout_buffered = true,
	})
end

return M
