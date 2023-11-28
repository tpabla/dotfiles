-- Autocompletion
return {
    'hrsh7th/nvim-cmp',
    lazy = false,
    event = 'InsertEnter',
    dependencies = {
        {'L3MON4D3/LuaSnip'},
        {'saadparwaiz1/cmp_luasnip'},
        { "hrsh7th/cmp-emoji" },
    },
    config = function()
    -- Here is where you configure the autocompletion settings.
    local lsp_zero = require('lsp-zero')
    lsp_zero.extend_cmp()

    -- And you can configure cmp even more, if you want to.
    local cmp = require('cmp')
    local cmp_action = lsp_zero.cmp_action()

    cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = lsp_zero.cmp_format(),
        mapping = cmp.mapping.preset.insert({
        ['<C-y>'] = cmp.mapping.complete(),
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
        ['<C-l>'] = cmp_action.luasnip_jump_forward(),
        ['<C-h>'] = cmp_action.luasnip_jump_backward(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'orgmode' },
        }, {
          { name = 'buffer' },
        }),
    })

    end
}
