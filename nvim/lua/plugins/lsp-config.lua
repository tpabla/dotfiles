-- LSP
return {
    'neovim/nvim-lspconfig',
    cmd = {'LspInfo', 'LspInstall', 'LspStart'},
    event = {'BufReadPre', 'BufNewFile'},
    dependencies = {
      {'hrsh7th/cmp-nvim-lsp'},
      {'williamboman/mason-lspconfig.nvim'},
    },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = {},
        handlers = {
        lsp_zero.default_setup,
        lua_ls = function()
            -- (Optional) Configure lua language server for neovim
            local lua_opts = lsp_zero.nvim_lua_ls()
            require('lspconfig').lua_ls.setup(lua_opts)
        end,
        }
      })

      require('lspconfig')['solargraph'].setup {
        cmd = {"withenv", "vendor/bundle/bundle", "exec", "solargraph", "stdio"},
      }
      require 'lspconfig'.tailwindcss.setup {
        capabilities = Capabilities,
       -- There add every filetype you want tailwind to work on
        filetypes = {
          "css",
          "scss",
          "sass",
          "postcss",
          "html",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "svelte",
          "vue",
          "rust",
        },
        init_options = {
          userLanguages = {
            rust = "html",
          },
        },

        on_attach = function(_, bufnr)
          require("tailwindcss-colors").buf_attach(bufnr)
        end,
        -- Here If any of files from list will exist tailwind lsp will activate.
        root_dir = require 'lspconfig'.util.root_pattern('tailwind.config.js', 'tailwind.config.ts', 'postcss.config.js',
          'postcss.config.ts', 'windi.config.ts'),
      }
    end
}
