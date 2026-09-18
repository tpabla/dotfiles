local languages = {
    "bash",
    "css",
    "diff",
    "dockerfile",
    "fish",
    "git_config",
    "git_rebase",
    "gitcommit",
    "gitignore",
    "go",
    "html",
    "javascript",
    "json",
    "lua",
    "make",
    "markdown",
    "markdown_inline",
    "mermaid",
    "python",
    "query",
    "regex",
    "ruby",
    "rust",
    "scss",
    "sql",
    "swift",
    "terraform",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "xml",
    "yaml",
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
