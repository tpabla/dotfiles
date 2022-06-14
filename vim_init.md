# Vim Init Config


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
### IDE Features
* [NerdTree](https://github.com/preservim/nerdtree)
  * This is a great file explorer, give a more IDE like feelings to vim.

### Language Server Protocol (LSP)
