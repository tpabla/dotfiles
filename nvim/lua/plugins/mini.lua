return {
  'echasnovski/mini.nvim',
  version = '*',
  config = function()
    require("mini.indentscope").setup({
      symbol = "|",
      options = { try_as_border = true },
    })
    require("mini.ai").setup({})
    require("mini.operators").setup({})
    require("mini.surround").setup({})
    require("mini.animate").setup({})
    require("mini.hipatterns").setup({})
    -- require("mini.hues").setup({})
    require("mini.move").setup({})
  end,
}
