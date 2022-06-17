NeovimConfig
============

## Key Bindings.
`let mapleader = ','`
*  the `<leader>` key is now set to `,` this allows for convenient and ergonomic
   access to it.  Also can be leverage for new commands in the future.
   * `nmap <leader>p :MarkdownPreview<CR>` This is an example of how to
   trigger a different plugins' features 
* `,p` Triggers Markdown Preview
* `,s` Sets the local buffer to have spell checking enabled.

## Plugin Management
* [Vim-Plug](https://github.com/junegunn/vim-plug)
  * After years of trying out vim installation methods, this has proven to be
    the easiest, however I will have to look into native neovim plugin
    installation at a later time.A
  * **TODO: Look in to native plugin management**

## Plugin Choices
* Plug 'tpope/vim-commentary'
  * Great for commenting things out with command gcc, you can select a visual
  block and it will bulk comment out the lines
* Plug 'ntpeters/vim-better-whitespace'
  * Using `<leader> <SPC>` you can easily strip whitespace from a file.
* Plug 'tpope/vim-surround'
  * Great for select and changing any symbols surrounding test, eg: Changing
  single quotes to double quotes would be a command like this `cs'"`
* Plug 'christoomey/vim-tmux-navigator'
  * Allows for easy navigation in tmux between vim panes, and tmux panes.
* Plug 'tpabla/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
  * A fork off a popular markdown previewing repository.  I only forked this to
  enable previewing of the current version mermaidjs syntax.
* Plug 'dhruvasagar/vim-table-mode'
  * Convenience plugin for working with tables.

### IDE Features
* [NerdTree](https://github.com/preservim/nerdtree)
  * This is a great file explorer, give a more IDE like feelings to vim.
* Plug 'dracula/vim', { 'as': 'dracula' }
  * Color scheme.
* Plug 'ryanoasis/vim-devicons'
  * Makes files in nerdtree look pretty.
* LSP Plugins
  * Plug 'neovim/nvim-lspconfig'
  * Plug 'hrsh7th/cmp-nvim-lsp'
  * Plug 'hrsh7th/cmp-buffer'
  * Plug 'hrsh7th/cmp-path'
  * Plug 'hrsh7th/cmp-cmdline'
  * Plug 'hrsh7th/nvim-cmp'
* File finder/grepper plugins
  * Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  * Plug 'nvim-lua/plenary.nvim'
  * Plug 'nvim-telescope/telescope.nvim'



### Language Server Protocol (LSP)
