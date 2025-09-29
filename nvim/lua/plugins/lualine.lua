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
        lualine_a = {
          {
            "buffers",
            show_filename_only = true,
            hide_filename_extension = false,
            show_modified_status = true,
            mode = 2, -- Shows buffer name + buffer index
            max_length = vim.o.columns * 2 / 3,
            symbols = {
              modified = ' ●',      -- Unsaved changes
              alternate_file = '#', -- Alternate buffer
              directory = '',     -- Directory indicator
            },
          }
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {
          {
            "tabs",
            tab_max_length = 40,
            max_length = vim.o.columns / 3,
            mode = 2, -- Shows tab number + tab name
            symbols = {
              modified = ' ●',
            },
          }
        }
      }
    end,
    keys = {
      { "<leader>l", "<cmd>bnext<cr>", desc = "Next buffer" },
      { "<leader>h", "<cmd>bprevious<cr>", desc = "Previous buffer" },
    },
  },
}
