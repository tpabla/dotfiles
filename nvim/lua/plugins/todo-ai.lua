return {
    dir = vim.fn.expand("~/Projects/todo-ai"),
    config = function()
        require("todo-ai").setup({
            provider = "claude",
            log_level = "DEBUG", -- Enable debug logging for development
        })
    end,
}
