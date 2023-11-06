--vim.g.mapleader = ',' Defined in lazy-plugins.lua for proper sequencing
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)
vim.keymap.set('n', '<leader>d', '<Cmd>NvimTreeToggle<CR>')
-- vim.keymap.set({'n', 'v', 'i'}, '<C-h>', '<C-w>h')
-- vim.keymap.set({'n', 'v', 'i'}, '<C-j>', '<C-w>j')
-- vim.keymap.set({'n', 'v', 'i'}, '<C-k>', '<C-w>k')
-- vim.keymap.set({'n', 'v', 'i'}, '<C-l>', '<C-w>l')

local telescope = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', telescope.find_files, {})
vim.keymap.set('n', '<leader>fg', telescope.live_grep, {})
vim.keymap.set('n', '<leader>fb', telescope.buffers, {})
vim.keymap.set('n', '<leader>fh', telescope.help_tags, {})

vim.keymap.set({'n', 'v', 'i'}, '<C-p>', telescope.find_files, {})

vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
