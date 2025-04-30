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

function is_work()
  local work_env = os.getenv("WORK")
  return work_env ~= nil
end

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = vim.api.nvim_create_augroup("auto_create_dir", { clear = true }),
    callback = function(event)
        local file = event.match
        -- Skip oil:// buffers
        if string.match(file, "^oil:") then
            return
        end
        local dir = vim.fn.fnamemodify(file, ":p:h")
        vim.fn.mkdir(dir, "p")
    end,
})

require("lazy").setup(
    "plugins",
    {
        install = {
          colorscheme = {
            'catpuccin',
          }
        },
        ui = {
            border = 'rounded',
        }
    }
)

-- defaults
vim.o.clipboard = 'unnamedplus' -- copy to the system clipboard
vim.o.encoding = 'utf-8'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.termguicolors = true
vim.o.swapfile = false
vim.o.undofile = true
vim.o.backup = false
vim.cmd('filetype plugin indent on')

-- indentation
vim.o.tabstop = 4
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.smartindent = true      -- Autoindent new lines
vim.o.autoindent = true      -- Autoindent new lines
vim.o.cindent = true          -- Autoindent new lines, smarter? (experimental)

-- Set highlight on search
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 8

-- Make line numbers default
vim.wo.number = true
vim.o.relativenumber = true

-- Disable mouse mode
vim.o.mouse = ''

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'

-- vim.o.colorcolumn = 80

-- for bufferline
vim.o.showtabline = 2

-- custom mapping for plugins
require('remap')



-- custom functions to be added to
local functions = require('functions')
vim.keymap.set({'n', 'i'}, '<leader>r', functions.reload)
