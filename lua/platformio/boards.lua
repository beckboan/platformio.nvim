local utils = require("platformio.utils")
local M = {}

function M.PIOBoardList(args)
	local raw_boards = vim.fn.systemlist("pio boards " .. args)
	local boards = {}
	for _, boardline in ipairs(raw_boards) do
		local board_info = { string.match(boardline, "^(%S*) .*Hz.*") }
		if board_info[1] then
			local name = board_info[1]
			if not vim.tbl_contains(boards, name) then
				table.insert(boards, name)
			end
		end
	end
	return table.concat(boards, "\n")
end

function M.PIOInit(board)
	-- Send commands to the terminal job
	local cmd = { "platformio", "project", "init", "--ide", "vim" }
	if board and board ~= "" then
		table.insert(cmd, "--board")
		table.insert(cmd, board)
	end

	utils.OpenTerm2(cmd)
end

function M.PIOSelectBoard(args)
	args = args or ""

	local winid, bufnr = utils.RunPIOWin("PIO Boards")

	vim.api.nvim_set_option_value("winhl", "Normal:MyHighlight", { win = winid })
	if winid < 0 then
		print("Failed to create window")
		return
	end

	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })

	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.filetype = "pioboards"
	vim.api.nvim_buf_set_keymap(
		bufnr,
		"n",
		"<CR>",
		[[:lua require("platformio.boards").PIOInit(vim.fn.expand("<cWORD>"))<CR>]],
		{ noremap = true, silent = true }
	)

	vim.api.nvim_echo({ { "Scanning Boards ...", "Normal" } }, false, {})

	local output = vim.fn.systemlist("platformio boards " .. args)
	vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

	-- Apply highlights to buffer content
	for i, line in ipairs(output) do
		if line:match("^Platform:") then
			utils.highlight_line(bufnr, i - 1, line, "^Platform:", "PIOPlatform")
		elseif line:match("^ID%s+MCU%s+Frequency%s+Flash%s+RAM%s+Name") then
			utils.highlight_line(bufnr, i - 1, line, "^ID%s+MCU%s+Frequency%s+Flash%s+RAM%s+Name$", "PIOTableHeader")
		elseif line:match("^=+$") then
			utils.highlight_line(bufnr, i - 1, line, "^=+$", "PIOSeparator")
		elseif line:match("^[%s%-]+$") then
			utils.highlight_line(bufnr, i - 1, line, "^[%s%-]+$", "PIOSeparator")
		elseif line:match("^%S") then
			utils.highlight_line(bufnr, i - 1, line, "^%S+", "PIOBoardID")
			-- utils.highlight_line(bufnr, i - 1, line, "%S+$", "PIOBoardName")
		end
	end
	vim.api.nvim_win_set_cursor(winid, { 1, 0 })
end

return M
