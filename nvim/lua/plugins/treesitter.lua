return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
    require'nvim-treesitter.configs'.setup({
        ensure_installed = {
          "bash",
          "fish",
          "go",
          "html",
          "json",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "regex",
          "ruby",
          "rust",
          "vim",
          "yaml",
          "swift",
        },
        sync_install = false,
        auto_install = true,
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = false,
        },
    })
    end,
}
