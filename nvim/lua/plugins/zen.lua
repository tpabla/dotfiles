return {
  "folke/zen-mode.nvim",
  dependencies = {
    {
      "joshuadanpeterson/typewriter.nvim",
      dependencies = { "nvim-treesitter/nvim-treesitter" },
      config = function()
        require("typewriter").setup({
          enable_notifications = false,
        })
      end,
    },
  },
  keys = {
    { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
  },
  opts = {
    on_open = function()
      vim.cmd("TWEnable")
    end,
    on_close = function()
      vim.cmd("TWDisable")
    end,
  },
}
