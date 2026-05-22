return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && rm -rf bin && npm install",
    init = function()
        local css_dir = vim.fn.stdpath("config") .. "/markdown-preview"
        vim.g.mkdp_theme = "dark"
        vim.g.mkdp_markdown_css = css_dir .. "/catppuccin-macchiato.css"
        vim.g.mkdp_highlight_css = css_dir .. "/catppuccin-macchiato-highlight.css"
    end,
}
