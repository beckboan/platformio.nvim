local M = {}

function M.OpenTerm(cmd, opts)
	opts = opts or ""
	-- Create a new terminal buffer
	local term_bufnr = vim.api.nvim_create_buf(false, true)
	local width = vim.o.columns -- Set window width to full screen width
	local height = math.floor(vim.o.lines * 0.5) -- Calculate 50% of the screen height

	local win_opts = {
		relative = "editor",
		width = width,
		height = height,
		row = vim.o.lines - height + 1,
		col = 1,
	}
	local win = vim.api.nvim_open_win(term_bufnr, true, win_opts)
	vim.api.nvim_set_option_value("winhl", "Normal:MyHighlight", { win = win })

	vim.api.nvim_set_current_buf(term_bufnr)
	vim.bo.buflisted = true

	-- Open a new terminal window
	vim.api.nvim_command("terminal")

	vim.fn.chansend(vim.b.terminal_job_id, cmd .. "\n")
	vim.fn.chansend(vim.b.terminal_job_id, "platformio run -t compiledb\n")

	if vim.api.nvim_buf_is_valid(term_bufnr) then
		vim.api.nvim_set_option_value("modifiable", false, { buf = term_bufnr })
		local move_cursor = function()
			vim.api.nvim_win_set_cursor(0, { vim.fn.line("$"), 0 })
		end

		vim.loop.new_timer():start(100, 0, vim.schedule_wrap(move_cursor))
	else
		print("Error: Terminal buffer not valid")
	end
end

return M
