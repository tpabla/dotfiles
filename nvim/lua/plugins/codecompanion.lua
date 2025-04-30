return {
  "olimorris/codecompanion.nvim",
  config = true,
  enabled = false,
  opts = {
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
        prompt = "Prompt ", -- Prompt used for interactive LLM calls
        provider = "telescope", -- default|telescope|mini_pick
        opts = {
          show_default_actions = true, -- Show the default actions in the action palette?
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
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    { "<leader>ai", "<cmd>CodeCompanionChat<cr>", desc = "CodeComapnion Chat" },
    { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "CodeComapnion Actions" },
  }
}
