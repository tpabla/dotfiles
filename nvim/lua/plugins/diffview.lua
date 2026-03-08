return {
    'sindrets/diffview.nvim',
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
        { "<leader>do", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
        { "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
        { "<leader>dh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview Repo History" },
        { "<leader>df", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
    },
    config = function()
        require("diffview").setup({
            view = {
                merge_tool = {
                    layout = "diff3_mixed",
                    disable_diagnostics = true,
                },
            },
        })
    end,
}
