return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    config = function()
        -- Cyberpunk colorscheme constants
        local colors = {
            -- Primary neon colors
            neon_green = "#00ff9f",
            neon_cyan = "#00d9ff",
            neon_magenta = "#ff00ff",
            neon_pink = "#ff79c6",
            neon_purple = "#bd93f9",
            neon_orange = "#ffb86c",

            -- Accent colors
            matrix_green = "#50fa7b",
            cyber_blue = "#8be9fd",
            warning_red = "#ff5555",
            muted_gray = "#6272a4",

            -- Background colors
            dark_bg = "#1a1a2e",
            code_bg = "#282a36",
        }

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

        -- Apply cyberpunk colorscheme for rendered markdown
        local highlight_groups = {
            -- Headers (rendered mode)
            RenderMarkdownH1 = { fg = colors.neon_green, bold = true },
            RenderMarkdownH2 = { fg = colors.neon_cyan, bold = true },
            RenderMarkdownH3 = { fg = colors.neon_magenta, bold = true },
            RenderMarkdownH4 = { fg = colors.neon_orange, bold = true },
            RenderMarkdownH5 = { fg = colors.neon_pink, bold = true },
            RenderMarkdownH6 = { fg = colors.neon_purple, bold = true },

            -- Code blocks
            RenderMarkdownCode = { bg = colors.dark_bg },
            RenderMarkdownCodeInline = { fg = colors.matrix_green, bg = colors.code_bg },

            -- Lists and bullets
            RenderMarkdownBullet = { fg = colors.neon_magenta },
            RenderMarkdownDash = { fg = colors.neon_magenta },

            -- Quotes
            RenderMarkdownQuote = { fg = colors.cyber_blue, italic = true },

            -- Tables
            RenderMarkdownTableHead = { fg = colors.neon_green, bg = colors.dark_bg, bold = true },
            RenderMarkdownTableRow = { fg = colors.neon_cyan },
            RenderMarkdownTableFill = { fg = colors.neon_magenta },

            -- Checkboxes
            RenderMarkdownChecked = { fg = colors.matrix_green },
            RenderMarkdownUnchecked = { fg = colors.warning_red },
            RenderMarkdownTodo = { fg = colors.neon_orange },
            RenderMarkdownImportant = { fg = colors.neon_pink },
            RenderMarkdownCancelled = { fg = colors.muted_gray, strikethrough = true },

            -- Callouts
            RenderMarkdownInfo = { fg = colors.cyber_blue },
            RenderMarkdownSuccess = { fg = colors.matrix_green },
            RenderMarkdownHint = { fg = colors.neon_orange },
            RenderMarkdownWarn = { fg = colors.neon_pink },
            RenderMarkdownError = { fg = colors.warning_red },

            -- Links
            RenderMarkdownLink = { fg = colors.neon_cyan, underline = true },

            -- Headers (editing mode)
            markdownH1 = { fg = colors.neon_green, bold = true },
            markdownH2 = { fg = colors.neon_cyan, bold = true },
            markdownH3 = { fg = colors.neon_magenta, bold = true },
            markdownH4 = { fg = colors.neon_orange, bold = true },
            markdownH5 = { fg = colors.neon_pink, bold = true },
            markdownH6 = { fg = colors.neon_purple, bold = true },

            -- Header delimiters (editing mode)
            markdownH1Delimiter = { fg = colors.neon_green, bold = true },
            markdownH2Delimiter = { fg = colors.neon_cyan, bold = true },
            markdownH3Delimiter = { fg = colors.neon_magenta, bold = true },
            markdownH4Delimiter = { fg = colors.neon_orange, bold = true },
            markdownH5Delimiter = { fg = colors.neon_pink, bold = true },
            markdownH6Delimiter = { fg = colors.neon_purple, bold = true },

            -- Code (editing mode)
            markdownCode = { fg = colors.matrix_green, bg = colors.code_bg },
            markdownCodeBlock = { fg = colors.matrix_green, bg = colors.dark_bg },
            markdownCodeDelimiter = { fg = colors.neon_magenta },

            -- Lists (editing mode)
            markdownListMarker = { fg = colors.neon_magenta },
            markdownOrderedListMarker = { fg = colors.neon_magenta },

            -- Links (editing mode)
            markdownLink = { fg = colors.neon_cyan, underline = true },
            markdownLinkText = { fg = colors.neon_pink },
            markdownUrl = { fg = colors.cyber_blue },

            -- Emphasis (editing mode)
            markdownItalic = { fg = colors.neon_pink, italic = true },
            markdownBold = { fg = colors.neon_green, bold = true },
            markdownBoldItalic = { fg = colors.neon_green, bold = true, italic = true },

            -- Other elements (editing mode)
            markdownBlockquote = { fg = colors.cyber_blue, italic = true },
            markdownRule = { fg = colors.neon_magenta },
            markdownStrike = { fg = colors.muted_gray, strikethrough = true },

            -- Treesitter highlights for consistency
            ["@markup.heading.1.markdown"] = { fg = colors.neon_green, bold = true },
            ["@markup.heading.2.markdown"] = { fg = colors.neon_cyan, bold = true },
            ["@markup.heading.3.markdown"] = { fg = colors.neon_magenta, bold = true },
            ["@markup.heading.4.markdown"] = { fg = colors.neon_orange, bold = true },
            ["@markup.heading.5.markdown"] = { fg = colors.neon_pink, bold = true },
            ["@markup.heading.6.markdown"] = { fg = colors.neon_purple, bold = true },
            ["@markup.raw.block.markdown"] = { fg = colors.matrix_green, bg = colors.dark_bg },
            ["@markup.raw.inline.markdown"] = { fg = colors.matrix_green, bg = colors.code_bg },
            ["@markup.list.markdown"] = { fg = colors.neon_magenta },
            ["@markup.link.markdown"] = { fg = colors.neon_cyan, underline = true },
            ["@markup.link.label.markdown"] = { fg = colors.neon_pink },
            ["@markup.link.url.markdown"] = { fg = colors.cyber_blue },
            ["@markup.italic.markdown"] = { fg = colors.neon_pink, italic = true },
            ["@markup.strong.markdown"] = { fg = colors.neon_green, bold = true },
            ["@markup.quote.markdown"] = { fg = colors.cyber_blue, italic = true },
            ["@markup.strikethrough.markdown"] = { fg = colors.muted_gray, strikethrough = true },
        }

        -- Apply all highlight groups
        for group, opts in pairs(highlight_groups) do
            vim.api.nvim_set_hl(0, group, opts)
        end
    end,
}
