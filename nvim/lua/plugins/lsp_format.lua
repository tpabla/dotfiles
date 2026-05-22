return {
  "lukas-reineke/lsp-format.nvim",
  config = function()
    require("lsp-format").setup {}
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local buf = args.buf
        -- ts_ls's built-in formatter would compete with eslint on TS files;
        -- skip it. eslint LSP attaches separately and handles format-on-save
        -- for ts/tsx via vim.lsp.buf.format -> EslintFixAll.
        if client and client.name == "ts_ls" then
          return
        end
        require("lsp-format").on_attach(client, buf)
      end,
    })
  end,
}
