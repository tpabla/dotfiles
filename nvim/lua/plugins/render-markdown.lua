-- Mermaid diagrams render through snacks.image as an image below their code
-- block. Their source is hidden here, not by snacks: snacks drawing over the
-- code gets cut off on nvim 0.12. The opening fence and code lines are hidden,
-- the closing fence is blanked and keeps the image. With the cursor inside a
-- block its source shows, with the live image below it.
local ns = vim.api.nvim_create_namespace("diagram_source")
local placements = setmetatable({}, { __mode = "k" })
local updated = setmetatable({}, { __mode = "k" })

local function cursor_inside(p)
    if vim.api.nvim_get_current_buf() ~= p.buf then return false end
    local row = vim.api.nvim_win_get_cursor(0)[1]
    return row >= p.opts.range[1] and row <= p.opts.range[3]
end

-- Only hide source that has an image to show instead: a diagram that fails
-- to render (e.g. mid-edit syntax error) keeps its source visible.
local function hide_source(p)
    local first, last = p.opts.range[1] - 1, p.opts.range[3] - 1 -- fence rows
    if last <= first then return end
    -- A placement can outlive its text for a moment (e.g. a buffer whose
    -- content was just replaced): only hide rows that are still its fences.
    local lines = vim.api.nvim_buf_get_lines(p.buf, first, last + 1, false)
    if #lines ~= last - first + 1 or not lines[1]:match("^%s*```") or not lines[#lines]:match("^%s*```") then
        return
    end
    vim.api.nvim_buf_set_extmark(p.buf, ns, first, 0, { end_row = last - 1, end_col = 0, conceal_lines = "" })
    vim.api.nvim_buf_set_extmark(p.buf, ns, last, 0, { end_col = #lines[#lines], conceal = "" })
end

-- Snacks drops conversion errors for inline images, so a broken diagram would
-- just show its source. Its error goes below the block and onto the line mmdc
-- names as a diagnostic.
local diag_ns = vim.api.nvim_create_namespace("diagram_error")
local last_diags = {}

-- mmdc's message without its stack trace, and the diagram line it names
local function diagram_error(p)
    local text = ""
    for _, step in ipairs(p.img._convert and p.img._convert.steps or {}) do
        if step.err then
            text = step.proc and vim.trim(step.proc:err()) or ""
            if text == "" then text = step.err end
        end
    end
    local lines = {}
    for _, l in ipairs(vim.split(text, "\n")) do
        if l:match("^%s+at ") or l:match("%(.*:%d+:%d+%)$") then break end
        if l ~= "" then table.insert(lines, (l:gsub("^Error: ", ""))) end
    end
    if #lines == 0 then lines = { "render failed" } end
    return lines, tonumber(text:match("on line (%d+)"))
end

-- Snacks doesn't always close a failed placement once its block changes, and
-- can hold more than one for the same block. It is only current while the
-- block still holds the source it failed on (snacks writes that to img.src).
local function is_current(p)
    local f = io.open(p.img.src, "r")
    if not f then return false end
    local src = f:read("*a")
    f:close()
    local lines = vim.api.nvim_buf_get_lines(p.buf, p.opts.range[1], p.opts.range[3] - 1, false)
    return vim.trim(table.concat(lines, "\n")) == vim.trim(src)
end

local function show_error(p)
    local lines, line = diagram_error(p)
    local first, last = p.opts.range[1] - 1, p.opts.range[3] - 1 -- fence rows
    local virt = { { { "mermaid error: " .. lines[1], "DiagnosticError" } } }
    for i = 2, #lines do table.insert(virt, { { "  " .. lines[i], "DiagnosticError" } }) end
    -- on the last source line: virtual lines on a fence vanish when render-markdown hides it
    local row = math.max(first, last - 1)
    if row < vim.api.nvim_buf_line_count(p.buf) then
        vim.api.nvim_buf_set_extmark(p.buf, ns, row, 0, { virt_lines = virt })
    end
    return {
        lnum = line and math.max(first + 1, math.min(first + line, last - 1)) or first,
        col = 0,
        severity = vim.diagnostic.severity.ERROR,
        source = "mermaid",
        message = table.concat(lines, "\n"),
    }
end

local function sync(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local diags, shown = {}, {}
    for p in pairs(placements) do
        if p.buf == buf and p.opts.type == "chart" and p.opts.range and not p.closed then
            if p:ready() then
                if not cursor_inside(p) then hide_source(p) end
            elseif p.img:failed() and not shown[p.opts.range[1]] and is_current(p) then
                shown[p.opts.range[1]] = true
                table.insert(diags, show_error(p))
            end
        end
    end
    if not vim.deep_equal(diags, last_diags[buf]) then
        last_diags[buf] = diags
        vim.diagnostic.set(diag_ns, buf, diags)
    end
end

local function sync_all()
    local bufs = {}
    for p in pairs(placements) do bufs[p.buf] = true end
    for buf in pairs(bufs) do sync(buf) end
end

-- mmdc arguments for the cyberpunk theme; colours carry meaning (see mermaid/cyberpunk.css)
local function mermaid_args(scale, bg)
    local dir = vim.fn.stdpath("config") .. "/mermaid/"
    return {
        "-i", "{src}", "-o", "{file}", "-b", bg or "transparent", "-s", scale or "{scale}",
        "-c", dir .. "cyberpunk.json", "-C", dir .. "cyberpunk.css",
    }
end

-- Pixel size of a PNG from its IHDR header, or nil
local function png_size(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local head = f:read(24)
    f:close()
    if not head or #head < 24 or head:sub(1, 8) ~= "\137PNG\r\n\26\n" then return nil end
    local w1, w2, w3, w4, h1, h2, h3, h4 = head:byte(17, 24)
    return w1 * 16777216 + w2 * 65536 + w3 * 256 + w4, h1 * 16777216 + h2 * 65536 + h3 * 256 + h4
end

-- Snacks sends PNGs unconverted and herdr drops ones that are too large. A PNG
-- bigger than the terminal is handed to snacks as a symlink without the .png
-- extension, so it goes through the magick step that scales it down.
local function fit_png(src)
    if type(src) ~= "string" or not src:match("%.png$") then return src end
    local stat = vim.uv.fs_stat(src)
    local w, h = png_size(src)
    local term = Snacks.image.terminal.size()
    if not (stat and w) or (w <= term.width and h <= term.height) then return src end
    local cache = Snacks.image.config.cache
    -- snacks caches by source path; keying the link on the terminal size too
    -- re-scales after a resize instead of reusing a smaller conversion
    local key = table.concat({ src, stat.mtime.sec, term.width, term.height }, ":")
    local link = ("%s/%s.large"):format(cache, vim.fn.sha256(key):sub(1, 16))
    if not vim.uv.fs_lstat(link) then
        vim.fn.mkdir(cache, "p")
        vim.uv.fs_symlink(src, link)
    end
    return link
end

-- Source of the mermaid block under the cursor, or nil
local function mermaid_at_cursor()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local parsed, parser = pcall(vim.treesitter.get_parser, 0, "markdown")
    if parsed and parser then parser:parse(true) end
    local ok, node = pcall(vim.treesitter.get_node, { pos = { row, 0 }, lang = "markdown", ignore_injections = true })
    while ok and node and node:type() ~= "fenced_code_block" do node = node:parent() end
    if not (ok and node) then return nil end
    local lang, content
    for child in node:iter_children() do
        if child:type() == "info_string" then lang = vim.treesitter.get_node_text(child, 0):match("%S+") end
        if child:type() == "code_fence_content" then content = vim.treesitter.get_node_text(child, 0) end
    end
    return lang == "mermaid" and content or nil
end

-- Opens the image in a new tab; its buffer goes away with the tab
local function open_in_tab(png)
    vim.cmd.tabedit(vim.fn.fnameescape(png))
    vim.bo.bufhidden = "wipe"
end

-- Snacks only scales images down to fit, so a small diagram stays small in its
-- own buffer. Render it large instead and let snacks fit it to the tab, but no
-- larger than the terminal: big images sent through herdr fail to show.
local function view_diagram()
    local src = mermaid_at_cursor()
    if not src then
        return vim.notify("No mermaid diagram under the cursor", vim.log.levels.WARN)
    end
    local base = vim.fn.tempname()
    vim.fn.writefile(vim.split(src, "\n"), base .. ".mmd")
    local cmd = { "mmdc" }
    for _, a in ipairs(mermaid_args("4")) do
        table.insert(cmd, (a:gsub("{src}", base .. ".mmd"):gsub("{file}", base .. ".png")))
    end
    vim.system(cmd, { text = true }, vim.schedule_wrap(function(r)
        if r.code ~= 0 then
            return vim.notify("mmdc failed:\n" .. r.stderr, vim.log.levels.ERROR)
        end
        local term = Snacks.image.terminal.size()
        local fit = string.format("%dx%d>", term.width, term.height)
        -- flat-coloured diagrams survive 64 colours, and the file shrinks ~6x
        vim.system({ "magick", base .. ".png", "-resize", fit, "+dither", "-colors", "64", base .. ".png" }, {},
            vim.schedule_wrap(function() open_in_tab(base .. ".png") end))
    end))
end

return {
    {
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
                    -- snacks.image renders these as diagrams
                    disable = { "mermaid" },
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
    },
    -- Draws images and mermaid diagrams inline in markdown via kitty graphics
    -- (through herdr: [terminal] kitty_graphics = true). Not lazy: it must be
    -- attached before the first markdown buffer opens.
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        config = function(_, opts)
            require("snacks").setup(opts)
            -- snacks sets images up on the first file read, so a markdown buffer
            -- built in memory (e.g. todo-ai slides) would never get diagrams
            require("snacks.image").setup()
            local convert = Snacks.image.convert.convert
            Snacks.image.convert.convert = function(o)
                o.src = fit_png(o.src)
                local done = o.on_done
                o.on_done = function(c)
                    if done then done(c) end
                    if c:error() then vim.schedule(sync_all) end
                end
                return convert(o)
            end
            -- on_update_pre only sees diagrams that rendered; track failed ones too
            local new = Snacks.image.placement.new
            Snacks.image.placement.new = function(...)
                local p = new(...)
                if p.opts.type == "chart" then
                    placements[p] = true
                    vim.schedule(function() sync(p.buf) end)
                end
                return p
            end
        end,
        init = function()
            vim.api.nvim_create_user_command("DiagramView", view_diagram,
                { desc = "Open the mermaid diagram under the cursor large, in a new tab" })
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "markdown",
                callback = function(ev)
                    vim.keymap.set("n", "<leader>dv", view_diagram, { buffer = ev.buf, desc = "Diagram view" })
                end,
            })
            -- nvim 0.11+ markdown highlights hide code fence lines outright, and an
            -- image attached to a hidden line is hidden with it. Keep fences as
            -- lines (render-markdown and sync() style them instead).
            -- https://github.com/neovim/neovim/discussions/34543
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "markdown",
                once = true,
                callback = function()
                    local parts = {}
                    for _, f in ipairs(vim.treesitter.query.get_files("markdown", "highlights")) do
                        table.insert(parts, table.concat(vim.fn.readfile(f), "\n"))
                    end
                    local query = table.concat(parts, "\n"):gsub('%(#set! conceal_lines ""%)', "")
                    vim.treesitter.query.set("markdown", "highlights", query)
                end,
            })
            vim.api.nvim_create_autocmd(
                { "BufWinEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI", "ModeChanged" },
                {
                    callback = function(ev)
                        if vim.bo[ev.buf].filetype == "markdown" then sync(ev.buf) end
                    end,
                }
            )
        end,
        opts = {
            image = {
                enabled = true,
                doc = {
                    -- diagrams: source hidden by sync() above; math: snacks' own conceal
                    conceal = function(_, type) return type == "math" end,
                    on_update_pre = function(p)
                        if updated[p] then return end
                        updated[p] = true
                        placements[p] = true
                        vim.schedule(function() sync(p.buf) end)
                    end,
                },
                convert = {
                    mermaid = function() return mermaid_args() end,
                    -- Scale rasters to the terminal instead of 1920x1080: nothing larger can show
                    magick = {
                        default = function()
                            local t = Snacks.image.terminal.size()
                            return { "{src}[0]", "-scale", ("%dx%d>"):format(t.width, t.height) }
                        end,
                    },
                },
            },
        },
    },
}
