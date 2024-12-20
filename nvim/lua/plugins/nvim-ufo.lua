return {
  {
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async",
    },
    event = "BufReadPost", -- Load on buffer read
    config = function()
      -- Setup ufo
      require("ufo").setup({
        provider_selector = function(bufnr, filetype, buftype)
          return { "treesitter", "indent" }
        end,
      })

      -- Fold settings
      vim.o.foldcolumn = "1" -- Show fold column
      vim.o.foldlevel = 99   -- Start unfolded
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true -- Enable folding

      -- Keybindings for folding
      vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open All Folds" })
      vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close All Folds" })
      vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds, { desc = "Open Folds Except Kinds" })
      vim.keymap.set("n", "zm", require("ufo").closeFoldsWith, { desc = "Close Folds With" })
    end,
  },
}
