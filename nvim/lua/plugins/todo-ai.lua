local dir = vim.fn.expand("~/Repos/todo-ai")

if vim.fn.isdirectory(dir) == 1 then
    return {
        dir = dir,
        dependencies = { "sindrets/diffview.nvim" },
        opts = {},
    }
end

-- Not cloned on this machine: keep nvim starting cleanly, but make every
-- todo-ai command and key say what is missing instead of doing nothing.
local function missing()
    vim.notify(
        "todo-ai is not installed: clone it to " .. dir .. "\n"
            .. "  git clone https://github.com/tpabla/todo-ai " .. dir .. "\n"
            .. "then restart nvim",
        vim.log.levels.ERROR
    )
end

for _, cmd in ipairs({ "TodoAI", "TodoAISend", "TodoAIFocus", "TodoAIScan", "TodoAIVisual" }) do
    vim.api.nvim_create_user_command(cmd, missing, { nargs = "*", range = true })
end
vim.keymap.set("n", "<leader>tc", missing, { desc = "todo-ai (not installed)" })
vim.keymap.set("n", "<leader>tf", missing, { desc = "todo-ai (not installed)" })
vim.keymap.set("n", "<leader>ts", missing, { desc = "todo-ai (not installed)" })
vim.keymap.set("v", "<leader>ti", missing, { desc = "todo-ai (not installed)" })

return {}
