# PLATFORMIO Plugin for NVIM Intergration

## Lua overhaul of https://github.com/normen/vim-pio


	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
		"Help: Press [Enter] on a Board line name to install",
		"",
	})
	vim.api.nvim_buf_set_lines(bufnr, 4, -1, false, output)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i = 1, 2 do
		local line = lines[i]
		if line:match("^Help:") then
			utils.highlight_line(bufnr, i - 1, line, "^Help:", "PIOMad")
		end
		if line:match("%[Enter%]") then
			utils.highlight_line(bufnr, i - 1, line, "%[Enter%]", "PIOHappy")
		end
		if line:match("Found %d+ packages") then
			utils.highlight_line(bufnr, i - 1, line, "%d+", "PIOHappy")
		end
	end
