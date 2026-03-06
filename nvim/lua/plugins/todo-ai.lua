return {
    dir = vim.fn.expand("~/Personal/todo-ai"),
    config = function()
        require("todo-ai").setup({
            provider = "claude-cli",
            model = "claude-opus-4.6",
            log_level = "DEBUG", -- Enable debug logging for development
        })
    end,
}
