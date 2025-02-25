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
      -- This is where all the LSP shenanigans will live
      local lsp_zero = require('lsp-zero')
      lsp_zero.extend_lspconfig()

      lsp_zero.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        lsp_zero.default_keymaps({
          buffer = bufnr,
          preserve_mappings = false,
        })

        vim.api.nvim_create_autocmd("CursorHold", {
          buffer = bufnr,
          callback = function()
            local opts = {
              focusable = false,
              close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
              border = 'rounded',
              source = 'always',
              prefix = ' ',
              scope = 'cursor',
            }
            vim.diagnostic.open_float(nil, opts)
          end
        })
      end)

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
        cmd = {"withenv", "~/Projects/easy_post/vendor/bundle/bundle", "exec", "solargraph", "stdio"},
      }

      require('lspconfig').gopls.setup {
        on_attach = function(client, bufnr)
          -- Format on save
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ timeout_ms = 2000 })
              vim.lsp.buf.code_action({
                context = {
                  only = { "source.organizeImports" } ,
                  diagnostics = {},
                },
                apply = true
              })
            end,
          })
        end,
      }

      require 'lspconfig'.tailwindcss.setup {
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
          "astro",
        },
        init_options = {
          userLanguages = {
            rust = "html",
          },
        },

        on_attach = function(_, bufnr)
          require("tailwindcss-colors").buf_attach(bufnr)
        end,
      }

    -- Here is where you configure the autocompletion settings.
    lsp_zero.extend_cmp()

    -- And you can configure cmp even more, if you want to.
    local cmp = require('cmp')
    local cmp_action = lsp_zero.cmp_action()

    cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = lsp_zero.cmp_format(),
        mapping = cmp.mapping.preset.insert({
          ['<C-y>'] = cmp.mapping.complete(),
          ['<C-u>'] = cmp.mapping.scroll_docs(-4),
          ['<C-d>'] = cmp.mapping.scroll_docs(4),
          ['<C-l>'] = cmp_action.luasnip_jump_forward(),
          ['<C-h>'] = cmp_action.luasnip_jump_backward(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'orgmode' },
        }, {
          { name = 'buffer' },
        }),
    })

    end
}
