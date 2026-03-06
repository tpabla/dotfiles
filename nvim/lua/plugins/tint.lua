return {
  "levouh/tint.nvim",
  config = function()
    require("tint").setup({
      tint = -45,  -- negative = darker, adjust to taste (-30 subtle, -60 strong)
      saturation = 0.6,  -- lower = more washed out
    })
  end,
}
