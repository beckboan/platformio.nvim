local utils = require("platformio.utils")

local M = {}

vim.api.nvim_set_keymap(
	"n",
	"<leader>pb",
	[[:lua require('platformio.boards').PIOBoardSelection('')<CR>]],
	{ noremap = true, silent = true }
)

return M
