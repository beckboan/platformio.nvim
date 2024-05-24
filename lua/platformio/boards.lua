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
	local cmd = "platformio project init --ide vim"
	if board and board ~= "" then
		cmd = cmd .. " --board " .. board
	end

	utils.OpenTerm(cmd)
end

function M.PIOBoardSelection(args)
	args = args or ""
	local bufnr = vim.fn.bufnr("PIO Boards")
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
		vim.bo.filetype = "pioboards"
		vim.api.nvim_buf_set_name(bufnr, "PIO Boards")
		vim.api.nvim_buf_set_keymap(
			bufnr,
			"n",
			"<CR>",
			[[:lua require("platformio.boards").PIOInit(vim.fn.expand("<cWORD>"))<CR>]],
			{ noremap = true, silent = true }
		)
	end
	print("Scanning PlatformIO boards..")
	local output = vim.fn.systemlist("platformio boards " .. args)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
	vim.api.nvim_command("normal! G")
	vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })
	vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })

	-- Set the cursor to the first visible line
	vim.api.nvim_win_set_cursor(winid, { 1, 0 })
end

-- M.PIOBoardSelection()

return M
