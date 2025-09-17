return {
  "lukas-reineke/headlines.nvim",
  dependencies = "nvim-treesitter/nvim-treesitter",
  ft = { "org" },
  opts = {
    org = {
      fat_headlines = true,
      fat_headline_lower_string = "—",
    },
  },
}
