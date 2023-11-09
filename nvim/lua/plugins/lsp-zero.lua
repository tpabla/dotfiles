return {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    lazy = true,
    config = false,
    init = function()
    -- Disable automatic setup, we are doing it manually
    vim.g.lsp_zero_extend_cmp = 0
    vim.g.lsp_zero_extend_lspconfig = 0
    local lsp_zero = require('lsp-zero')

    lsp_zero.on_attach(function(client, bufnr)
lsp_zero.default_keymaps({buffer = bufnr})
    end)
    end,
}
