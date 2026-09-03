local languages = {
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
}

return {
    "nvim-treesitter/nvim-treesitter",
    -- The main branch is the only one compatible with Neovim 0.12; master is
    -- locked to 0.11 and its query directives crash under 0.12's handler signature.
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").install(languages)

        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                -- Fails for filetypes with no installed parser, which is not an error.
                pcall(vim.treesitter.start, args.buf)
            end,
        })
    end,
}
