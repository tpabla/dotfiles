-- herdr TUI sets HERDR_PANE_ID; herdr-app (via herdr-core) sets HC_TERMINAL_ID.
local in_herdr_tui = vim.env.HERDR_PANE_ID ~= nil
local in_herdr_app = not in_herdr_tui and vim.env.HC_TERMINAL_ID ~= nil

-- herdr-app's vim-nav mod sends ctrl-h/j/k/l here; at an nvim edge, hand off to pane.go.
local function herdr_app_navigate(wincmd, direction)
  local win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() == win then
    vim.fn.jobstart({ "herdr-app", "do", "pane.go", "--direction", direction }, { detach = true })
  end
end

return {
  "bojackduy/nvim-herdr-navigation",
  submodules = false,
  cond = function()
    return in_herdr_tui or in_herdr_app
  end,
  event = "VeryLazy",
  init = function(plugin)
    vim.opt.rtp:prepend(plugin.dir .. "/nvim-herdr-navigation")
  end,
  config = function()
    if in_herdr_app then
      for key, nav in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
        vim.keymap.set("n", "<C-" .. key .. ">", function()
          herdr_app_navigate(key, nav)
        end, { silent = true, desc = "Window/herdr pane " .. nav })
      end
      return
    end
    vim.schedule(function()
      require("herdr-navigation").setup({
        keybindings = {
          left = "<C-h>",
          down = "<C-j>",
          up = "<C-k>",
          right = "<C-l>",
        },
      })
    end)
  end,
}
