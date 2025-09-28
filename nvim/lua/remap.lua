--vim.g.mapleader = ',' Defined in lazy-plugins.lua for proper sequencing
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)


vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set('n', '\\\\', '<Cmd>Noice dismiss<CR>')
