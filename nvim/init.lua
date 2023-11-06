vim.g.mapleader = ","

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(
    "plugins",
    {
        ui = {
            border = 'rounded',
        }
    }
)

vim.o.clipboard = 'unnamedplus' -- copy to the system clipboard
vim.o.encoding = 'utf-8'
vim.o.ignorecase = true
vim.o.termguicolors = true

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true

vim.o.swapfile = false
vim.o.undofile = true
vim.o.backup = false
vim.o.textwidth=100

-- Set highlight on search
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 8

-- Make line numbers default
vim.wo.number = true
vim.o.relativenumber = true

-- Disable mouse mode
vim.o.mouse = ''

-- Enable break indent
vim.o.breakindent = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'

vim.o.colorcolumn = 80

-- custom mapping for plugins
require('remap')

-- custom functions to be added to
local test = require('functions')
vim.keymap.set({'n', 'i'}, '<leader>r', test.reload)
