return {
    "christoomey/vim-tmux-navigator",
    cond = function()
        return vim.env.HERDR_PANE_ID == nil and vim.env.HC_TERMINAL_ID == nil
    end,
}
