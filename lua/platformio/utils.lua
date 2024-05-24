local M = {}

function M.PIOInit(board)
	local term_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(term_bufnr)
	vim.api.nvim_command("term")

	local cmd = "platformio project init --ide vim"
	if board and board ~= "" then
		cmd = cmd .. " --board " .. board
	end

	vim.fn.chansend(vim.b.terminal_job_id, cmd .. "\n")
	vim.fn.chansend(vim.b.terminal_job_id, "platformio run -t compiledb\n")

	vim.api.nvim_buf_set_option(term_bufnr, "modifiable", false)
end

return M
