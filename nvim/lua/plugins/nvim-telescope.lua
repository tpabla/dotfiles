return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.4',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'folke/which-key.nvim'
  },
  opts = {
    defaults = {
      file_ignore_patterns = {
        "cassettes",
        "test-support",
        "vendor"
      }
    }
  },
  config = function()
    local builtin = require('telescope.builtin')
    local action_state = require('telescope.actions.state')
    local actions = require('telescope.actions')

    buffer_searcher = function()
      builtin.buffers {
        sort_mru = true,
        ignore_current_buffer = true,
        show_all_buffers = false,
        attach_mappings = function(prompt_bufnr, map)
          local refresh_buffer_searcher = function()
            actions.close(prompt_bufnr)
            vim.schedule(buffer_searcher)
          end

          local delete_buf = function()
            local selection = action_state.get_selected_entry()
            vim.api.nvim_buf_delete(selection.bufnr, { force = true })
            refresh_buffer_searcher()
          end

          local delete_multiple_buf = function()
            local picker = action_state.get_current_picker(prompt_bufnr)
            local selection = picker:get_multi_selection()
            for _, entry in ipairs(selection) do
              vim.api.nvim_buf_delete(entry.bufnr, { force = true })
            end
            refresh_buffer_searcher()
          end

          map('n', 'dd', delete_buf)
          map('n', '<C-d>', delete_multiple_buf)
          map('i', '<C-d>', delete_multiple_buf)

          return true
        end
      }
    end

    -- Telescope keymaps
    vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>fb', buffer_searcher, {})
    vim.keymap.set('n', '_', buffer_searcher, {})
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
    vim.keymap.set({ 'n', 'v', 'i' }, '<C-p>', builtin.find_files, {})

    -- Which-key integration
    local wk = require("which-key")
    wk.add({
      { "<C-p>", desc = "Find Files" },
      { "<leader>f", group = "Find" },
      { "<leader>fb", desc = "Find Buffers" },
      { "<leader>ff", desc = "Find Files" },
      { "<leader>fg", desc = "Live Grep" },
      { "<leader>fh", desc = "Help Tags" },
      { "_", desc = "Find Buffers" },
    })
  end
}
