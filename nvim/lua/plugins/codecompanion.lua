return {
  "olimorris/codecompanion.nvim",
  config = true,
  enabled = true,
  opts = {
    extensions = {
      history = {
        enabled = true,
        opts = {
          keymap = "gh",
          save_chat_keymap = "sc",
          auto_save = false,
          auto_generate_title = true,
          continue_last_chat = false,
          delete_on_clearing_chat = false,
          picker = "telescope",
          enable_logging = true,
          dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
        },
      },
      mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          make_vars = true,
          make_slash_commands = true,
          show_result_in_chat = true,
        },
      },
      vectorcode = {
        opts = {
          add_tool = true,
        },
      },
    },
    strategies = {
      -- Change the default chat adapter
      chat = {
        adapter = "anthropic",
      },
    },
    display = {
      action_palette = {
        width = 95,
        height = 10,
        -- prompt = "Prompt ",                   -- Prompt used for interactive LLM calls
        provider = "telescope",               -- default|telescope|mini_pick
        opts = {
          show_default_actions = true,        -- Show the default actions in the action palette?
          show_default_prompt_library = true, -- Show the default prompt library in the action palette?
        },
      },
      chat = {
        window = {
          layout = "vertical",
          position = "right",
        },
        slash_commands = {
          opts = {
            provider = "telescope",
          },
        },
      }
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
    "nvim-treesitter/nvim-treesitter",
    "j-hui/fidget.nvim",                    -- Display status
    "ravitemer/codecompanion-history.nvim", -- Save and load conversation history
    {
      "ravitemer/mcphub.nvim",              -- Manage MCP servers
      cmd = "MCPHub",
      build = "npm install -g mcp-hub@latest",
      config = true,
    },
    {
      "Davidyz/VectorCode", -- Index and search code in your repositories
      version = "*",
      build = "pipx upgrade vectorcode",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
    {
      "HakonHarnes/img-clip.nvim", -- Share images with the chat buffer
      event = "VeryLazy",
      cmd = "PasteImage",
      opts = {
        filetypes = {
          codecompanion = {
            prompt_for_file_name = false,
            template = "[Image]($FILE_PATH)",
            use_absolute_path = true,
          },
        },
      },
    },
    { "echasnovski/mini.pick", config = true },
    { "ibhagwan/fzf-lua",      config = true },
  },
  keys = {
    { "<leader>ai", "<cmd>CodeCompanionChat<cr>",    desc = "CodeComapnion Chat" },
    { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "CodeComapnion Actions" },
  }
}
