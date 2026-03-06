return {
    'sindrets/diffview.nvim',
    keys = {
        { "<leader>do", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
        { "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
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
