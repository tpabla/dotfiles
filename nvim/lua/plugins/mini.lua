return {
  'echasnovski/mini.nvim',
  version = '*',
  config = function()
    require("mini.ai").setup({})
    require("mini.align").setup({})
    require("mini.operators").setup({})
    require("mini.surround").setup({})
    require("mini.hipatterns").setup({})
    require("mini.move").setup({})
    require("mini.pick").setup({})
  end,
}
