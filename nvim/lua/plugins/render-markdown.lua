return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    config = function()
        require("render-markdown").setup({
            heading = {
                enabled = true,
                sign = false,
                icons = { "█ ", "▓▓ ", "▒▒▒ ", "░░░░ ", "░░░░░ ", "░░░░░░ " },
                backgrounds = {},
            },
            code = {
                enabled = true,
                sign = false,
                style = "full",
                width = "full",
                border = "thin",
                above = "▄",
                below = "▀",
            },
            dash = {
                enabled = true,
                icon = "─",
                width = "full",
            },
            bullet = {
                enabled = true,
                icons = { "◆", "◇", "◈", "◉" },
            },
            checkbox = {
                enabled = true,
                unchecked = {
                    icon = "󰄱 ",
                },
                checked = {
                    icon = "󰱒 ",
                },
                custom = {
                    todo = { raw = "[~]", rendered = "󰥔 " },
                    important = { raw = "[!]", rendered = "󰀨 " },
                    cancelled = { raw = "[-]", rendered = "󰜺 " },
                },
            },
            quote = {
                enabled = true,
                icon = "▎",
            },
            pipe_table = {
                enabled = true,
                preset = "heavy",
                style = "full",
            },
            callout = {
                note = { raw = "[!NOTE]", rendered = "󰋽 Note" },
                tip = { raw = "[!TIP]", rendered = "󰌶 Tip" },
                important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important" },
                warning = { raw = "[!WARNING]", rendered = "󰀪 Warning" },
                caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution" },
            },
            link = {
                enabled = true,
                image = "󰥶 ",
                hyperlink = "󰌹 ",
                custom = {
                    web = { pattern = "^https?://", icon = "󰖟 " },
                    github = { pattern = "github%.com", icon = " " },
                },
            },
            sign = {
                enabled = false,
            },
            indent = {
                skip_level = 1,
                enabled = false,
                skip_heading = false,
            },
        })

        -- Cyberpunk color scheme
        vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#00ff9f", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#00d9ff", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#ff00ff", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = "#ffb86c", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = "#ff79c6", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = "#bd93f9", bold = true })

        vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#1a1a2e" })
        vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { fg = "#50fa7b", bg = "#282a36" })
        vim.api.nvim_set_hl(0, "RenderMarkdownBullet", { fg = "#ff00ff" })
        vim.api.nvim_set_hl(0, "RenderMarkdownQuote", { fg = "#8be9fd", italic = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownDash", { fg = "#ff00ff" })

        vim.api.nvim_set_hl(0, "RenderMarkdownTableHead", { fg = "#00ff9f", bg = "#1a1a2e", bold = true })
        vim.api.nvim_set_hl(0, "RenderMarkdownTableRow", { fg = "#00d9ff" })
        vim.api.nvim_set_hl(0, "RenderMarkdownTableFill", { fg = "#ff00ff" })

        vim.api.nvim_set_hl(0, "RenderMarkdownChecked", { fg = "#50fa7b" })
        vim.api.nvim_set_hl(0, "RenderMarkdownUnchecked", { fg = "#ff5555" })
        vim.api.nvim_set_hl(0, "RenderMarkdownTodo", { fg = "#ffb86c" })
        vim.api.nvim_set_hl(0, "RenderMarkdownImportant", { fg = "#ff79c6" })
        vim.api.nvim_set_hl(0, "RenderMarkdownCancelled", { fg = "#6272a4", strikethrough = true })

        vim.api.nvim_set_hl(0, "RenderMarkdownInfo", { fg = "#8be9fd" })
        vim.api.nvim_set_hl(0, "RenderMarkdownSuccess", { fg = "#50fa7b" })
        vim.api.nvim_set_hl(0, "RenderMarkdownHint", { fg = "#ffb86c" })
        vim.api.nvim_set_hl(0, "RenderMarkdownWarn", { fg = "#ff79c6" })
        vim.api.nvim_set_hl(0, "RenderMarkdownError", { fg = "#ff5555" })

        vim.api.nvim_set_hl(0, "RenderMarkdownLink", { fg = "#00d9ff", underline = true })
    end,
}
