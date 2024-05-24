local M = {}

function M.OpenTerm(cmd, opts)
	opts = opts or ""
	-- Create a new terminal buffer
	local term_bufnr = vim.api.nvim_create_buf(false, true)

	-- Set the newly created buffer as the current buffer
	vim.api.nvim_set_current_buf(term_bufnr)

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
