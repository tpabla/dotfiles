local skull_header = {

   '                             ',
   '        Get to work.         ',
   '                             ',
   ' ███████████████████████████ ',
   ' ███████▀▀▀░░░░░░░▀▀▀███████ ',
   ' ████▀░░░░░░░░░░░░░░░░░▀████ ',
   ' ███│░░░░░░░░░░░░░░░░░░░│███ ',
   ' ██▌│░░░░░░░░░░░░░░░░░░░│▐██ ',
   ' ██░└┐░░░░░░░░░░░░░░░░░┌┘░██ ',
   ' ██░░└┐░░░░░░░░░░░░░░░┌┘░░██ ',
   ' ██░░┌┘▄▄▄▄▄░░░░░▄▄▄▄▄└┐░░██ ',
   ' ██▌░│██████▌░░░▐██████│░▐██ ',
   ' ███░│▐███▀▀░░▄░░▀▀███▌│░███ ',
   ' ██▀─┘░░░░░░░▐█▌░░░░░░░└─▀██ ',
   ' ██▄░░░▄▄▄▓░░▀█▀░░▓▄▄▄░░░▄██ ',
   ' ████▄─┘██▌░░░░░░░▐██└─▄████ ',
   ' █████░░▐█─┬┬┬┬┬┬┬─█▌░░█████ ',
   ' ████▌░░░▀┬┼┼┼┼┼┼┼┬▀░░░▐████ ',
   ' █████▄░░░└┴┴┴┴┴┴┴┘░░░▄█████ ',
   ' ███████▄░░░░░░░░░░░▄███████ ',
   ' ██████████▄▄▄▄▄▄▄██████████ ',
   '                             ',
   '                             ',
}

return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = function()
    require('dashboard').setup({
     theme = 'hyper',
      config = {
        header = skull_header,
        week_header = {
         enable = false,
        },
        project = {
          enable = false
        },
        shortcut = {
          { desc = '󰊳 Update', group = '@property', action = 'Lazy update', key = 'u' },
          {
            icon = ' ',
            icon_hl = '@variable',
            desc = 'Files',
            group = 'Label',
            action = 'Telescope find_files',
            key = 'f',
          },
        },
      },
    })
  end,
  dependencies = { {'nvim-tree/nvim-web-devicons'}}
}
