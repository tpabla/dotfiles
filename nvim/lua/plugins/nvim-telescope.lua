return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.4',
    dependencies = {
        'nvim-lua/plenary.nvim'
    },
    opts = {
      defaults = {
        file_ignore_patterns = {
          "cassettes",
          "test-support",
        }
      }
    }
}
