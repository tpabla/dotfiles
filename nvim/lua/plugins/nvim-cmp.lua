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
    end
}
