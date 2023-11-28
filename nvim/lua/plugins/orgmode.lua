return {
  'nvim-orgmode/orgmode',
  dependencies = {
    { 'nvim-treesitter/nvim-treesitter', lazy = true },
    { 'akinsho/org-bullets.nvim'},
    { "folke/which-key.nvim" },
  },
  ft = { 'org' },
  event = 'VeryLazy',
  config = function()
    -- Load treesitter grammar for org
    require('orgmode').setup_ts_grammar()

    -- Setup treesitter
    require('nvim-treesitter.configs').setup({
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'org' },
      },
      ensure_installed = { 'org' },
    })

    -- Setup org-bullets
    require('org-bullets').setup()

    -- Setup orgmode
    require('orgmode').setup({
      org_agenda_files = '~/orgfiles/**/*',
      org_default_notes_file = '~/orgfiles/refile.org',

      prefix = '<Leader>o',
      mappings = {
        agenda = {
          org_agenda_set_tags = '<prefix>T',
        },
        org = {
          org_toggle_checkbox = '<leader>x',
          org_todo = '<prefix>tl',
          org_todo_prev = '<prefix>th',
          org_deadline = '<prefix>sd',
          org_schedule = '<prefix>ss',
          org_time_stamp = '<prefix>st.',
          org_clock_in = '<prefix>sc',
          org_clock_out = '<prefix>sC',
          org_clock_cancel = '<prefix>sx',
          org_set_tags_command = '<prefix>T',
        },
      },
    })

    local wk = require("which-key")
    wk.register({
      t = {
        name = "TODO Methods",
        h = "Previous TODO State",
        l = "Next TODO State"
      },
      s = {
        name = "Scheduling TODO's",
        s = "Schedule",
        d = "Deadline",
        t = "Timestamp",
        c = "Clock in",
        C = "Clock Out",
        x = "Clock Cancel",
      }
    },
    {
      prefix = "<leader>o"
    })
  end,
}
