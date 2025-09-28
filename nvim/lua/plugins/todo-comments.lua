return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("todo-comments").setup({
      signs = true,
      sign_priority = 8,
      keywords = {
        FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
      gui = { "bold" },
      merge_keywords = true,
      highlight = {
        multiline = true,
        before = "",
        keyword = "wide",
        after = "fg",
        pattern = [[.*<(KEYWORDS)\s*:]],
        comments_only = true,
        max_line_len = 400,
        exclude = {},
        -- Custom pattern to exclude @ai from after highlighting
        after_pattern = [[@ai]],
      },
      colors = {
        error = { "#ff5555" },      -- Cyberpunk red
        warning = { "#ffb86c" },    -- Cyberpunk orange
        info = { "#8be9fd" },       -- Cyberpunk cyan
        hint = { "#50fa7b" },       -- Cyberpunk green
        default = { "#bd93f9" },    -- Cyberpunk purple
        test = { "#ff79c6" },       -- Cyberpunk pink
      },
      search = {
        command = "rg",
        args = {
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
        },
        pattern = [[\b(KEYWORDS):]], -- ripgrep regex
      },
    })

    -- Additional cyberpunk highlight groups to match render-markdown
    vim.api.nvim_set_hl(0, "TodoBgFIX", { fg = "#ff5555", bg = "#1a1a2e", bold = true })
    vim.api.nvim_set_hl(0, "TodoBgHACK", { fg = "#ffb86c", bg = "#1a1a2e", bold = true })
    vim.api.nvim_set_hl(0, "TodoBgTODO", { fg = "#8be9fd", bg = "#1a1a2e", bold = true })
    vim.api.nvim_set_hl(0, "TodoBgNOTE", { fg = "#50fa7b", bg = "#1a1a2e", bold = true })
    vim.api.nvim_set_hl(0, "TodoBgTEST", { fg = "#ff79c6", bg = "#1a1a2e", bold = true })
    vim.api.nvim_set_hl(0, "TodoBgWARN", { fg = "#ffb86c", bg = "#1a1a2e", bold = true })
    vim.api.nvim_set_hl(0, "TodoBgPERF", { fg = "#bd93f9", bg = "#1a1a2e", bold = true })

    -- DRY tags will be added by TodoAI integration
    vim.api.nvim_set_hl(0, "TodoBgDRY", { fg = "#50fa7b", bg = "#1a1a2e", bold = true })    -- Matrix green
    vim.api.nvim_set_hl(0, "TodoBgUTIL", { fg = "#8be9fd", bg = "#1a1a2e", bold = true })   -- Cyber cyan
    vim.api.nvim_set_hl(0, "TodoBgHELPER", { fg = "#ff79c6", bg = "#1a1a2e", bold = true }) -- Hot pink
    vim.api.nvim_set_hl(0, "TodoBgPATTERN", { fg = "#ffb86c", bg = "#1a1a2e", bold = true }) -- Cyber orange
    vim.api.nvim_set_hl(0, "TodoBgCOMMON", { fg = "#bd93f9", bg = "#1a1a2e", bold = true }) -- Electric purple
    vim.api.nvim_set_hl(0, "TodoBgSHARED", { fg = "#ff5555", bg = "#1a1a2e", bold = true }) -- Neon red
  end,
}
