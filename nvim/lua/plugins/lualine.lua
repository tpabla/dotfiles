return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      -- Customize lualine options here
      opts.options = {
        theme = "auto",
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
        disabled_filetypes = { statusline = { "dashboard", "alpha" } },
      }
      opts.sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      }
      opts.tabline = {
        lualine_a = { "buffers" },
        lualine_z = { "tabs" },
      }
    end,
    keys = {
      { "<leader>l", "<cmd>bnext<cr>", desc = "Next buffer" },
      { "<leader>h", "<cmd>bprevious<cr>", desc = "Previous buffer" },
    },
  },
}
