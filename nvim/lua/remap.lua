--vim.g.mapleader = ',' Defined in lazy-plugins.lua for proper sequencing
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

local telescope = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', telescope.find_files, {})
vim.keymap.set('n', '<leader>fg', telescope.live_grep, {})
-- vim.keymap.set('n', '<leader>fb', telescope.buffers, {})
vim.keymap.set('n', '_', telescope.buffers, {})
vim.keymap.set('n', '<leader>fh', telescope.help_tags, {})

vim.keymap.set({ 'n', 'v', 'i' }, '<C-p>', telescope.find_files, {})

vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set('n', '\\\\', '<Cmd>Noice dismiss<CR>')

local wk = require("which-key")
