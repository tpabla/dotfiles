return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
  enabled = true,
  opts = {
    provider = "openai",
    providers = {
      -- behaviour = {
      --     enable_cursor_planning_mode = true, -- enable cursor planning mode!
      -- },
      lambda = {
        __inherited_from = "openai",
        api_key_name="LAMBDA_API_KEY",
        endpoint = "https://api.lambdalabs.com/v1",
        model = 'llama-4-maverick-17b-128e-instruct-fp8',
        disable_tools = false,
        extra_request_body = {
          max_tokens = 1000000,  -- Set a reasonable token limit
        },
      },
      openai = {
          endpoint = "https://api.openai.com/v1/",  -- OpenAI endpoint
          model = "o3-mini",  -- Set your preferred OpenAI model (e.g., gpt-4, gpt-3.5-turbo)
          extra_request_body = {
            temperature = 0.7,  -- Adjust as needed
            max_completion_tokens = 32768,  -- Set a reasonable token limit
          },
      },
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-sonnet-4-20250514",
        extra_request_body = {
          temperature = 0.5,  -- Adjust as needed
          max_tokens = 32768,  -- Set a reasonable token limit
        },
      },
      ollama = {
        endpoint = "http://127.0.0.1:11434", -- Note that there is no /v1 at the end.
        model = "qwen3:8b",
      },
    },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "echasnovski/mini.pick", -- for file_selector provider mini.pick
    "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
    "ibhagwan/fzf-lua", -- for file_selector provider fzf
    "stevearc/dressing.nvim", -- for input provider dressing
    "folke/snacks.nvim", -- for input provider snacks
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
