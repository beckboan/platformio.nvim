local Terminal = require("toggleterm.terminal").Terminal

local M = {}

-- local buffer_stack = {} -- Track buffer numbers for opened PIO Term buffers
M.PIO_WIN_ID = nil -- Track the PIO Term window ID
M.PIO_TERM = nil

local term = Terminal:new({
	direction = "horizontal",
	float_opts = {
		border = "double",
	},
	on_open = function(term)
		vim.cmd("startinsert!")
		vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
	end,
	on_close = function(term)
		vim.cmd("startinsert!")
	end,
})

vim.keymap.set("t", "<esc>", [[<C-\><C-n>]])
vim.keymap.set("t", "jk", [[<C-\><C-n>]])
vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]])
vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]])
vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]])
vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]])
vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]])

local function find_existing_buf(name)
	local name_only = name:gsub(".*/", "") -- Extract filename from full path
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) then
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			local bufname_only = bufname:gsub(".*/", "") -- Extract filename from full path
			if bufname_only == name_only then
				return bufnr
			end
		end
	end
	return nil
end

local function print_buffers()
	local buf_list = vim.api.nvim_list_bufs()
	for _, bufnr in ipairs(buf_list) do
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		print("Buffer", bufnr, ":", bufname)
	end
end

function M.OpenTerm(input_cmd, opts)
	if not term:is_open() then
		term:open()
	end
	term:send(input_cmd, false)
end

function M.RunPIOWin(bufname)
	local bufnr = find_existing_buf(bufname)

	if bufnr == nil then
		bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, bufname)
		vim.api.nvim_buf_set_option(bufnr, "buflisted", true)
	end

	-- if not vim.tbl_contains(buffer_stack, bufnr) then
	-- 	table.insert(buffer_stack, bufnr)
	-- end
	--
	-- local previous_bufnr = buffer_stack[#buffer_stack - 1]
	-- if previous_bufnr and vim.api.nvim_buf_is_valid(previous_bufnr) then
	-- 	vim.api.nvim_buf_set_option(previous_bufnr, "buflisted", true)
	-- end

	if not PIO_WIN_ID or not vim.api.nvim_win_is_valid(PIO_WIN_ID) then
		local win_opts = {
			focusable = true,
			style = "minimal",
			split = "below",
		}
		PIO_WIN_ID = vim.api.nvim_open_win(bufnr, true, win_opts)
	else
		vim.api.nvim_set_current_win(PIO_WIN_ID)
	end

	vim.api.nvim_win_set_buf(PIO_WIN_ID, bufnr)

	-- vim.api.nvim_buf_set_keymap(
	-- 	bufnr,
	-- 	"n",
	-- 	"q",
	-- 	':lua require("platformio.utils").HandleBufferClose()<CR>',
	-- 	{ noremap = true, silent = true }
	-- )

	return PIO_WIN_ID, bufnr
end

function M.highlight_line(bufnr, line_nr, line, pattern, hl_group)
	local start_col, end_col = string.find(line, pattern)
	if start_col then
		local ns_id = vim.api.nvim_create_namespace("pio_highlight")
		vim.api.nvim_buf_add_highlight(bufnr, ns_id, hl_group, line_nr, start_col - 1, end_col)
	end
end

function M.create_highlight_groups(groups)
	for group_name, attributes in pairs(groups) do
		local hl_attrs = {}

		-- Iterate over the attributes and set them in the hl_attrs table
		for attr_name, attr_value in pairs(attributes) do
			-- Skip attributes with nil values
			if attr_value ~= nil then
				-- Convert boolean values to numbers
				if type(attr_value) == "boolean" then
					attr_value = attr_value and 1 or 0
				end
				hl_attrs[attr_name] = attr_value
			end
		end

		-- Set the highlight group using vim.api.nvim_set_hl
		vim.api.nvim_set_hl(0, group_name, hl_attrs)
	end
end

-- function M.HandleBufferClose()
-- 	local bufnr = vim.api.nvim_get_current_buf()
-- 	print(bufnr)
--
-- 	for i, buf in ipairs(buffer_stack) do
-- 		if buf == bufnr then
-- 			table.remove(buffer_stack, i)
-- 			vim.api.nvim_buf_delete(bufnr, { force = true })
-- 			break
-- 		end
-- 	end
--
-- 	local previous_bufnr = buffer_stack[#buffer_stack]
--
-- 	print(vim.api.nvim_buf_is_valid(previous_bufnr))
-- 	local bufname = vim.api.nvim_buf_get_name(previous_bufnr)
-- 	print(bufname)
--
-- 	if previous_bufnr and vim.api.nvim_buf_is_valid(previous_bufnr) then
-- 		vim.api.nvim_win_set_buf(PIO_WIN_ID, previous_bufnr)
-- 	else
-- 		if #vim.api.nvim_list_wins() > 1 then
-- 			vim.cmd("close")
-- 			PIO_WIN_ID = nil
-- 		else
-- 			vim.cmd("enew")
-- 		end
-- 	end
-- end

return M
