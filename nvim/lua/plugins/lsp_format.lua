return {
  "lukas-reineke/lsp-format.nvim",
  config = function()
    require("lsp-format").setup {}
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local buf = args.buf
        local ft = vim.bo[buf].filetype
        if ft == "typescript" or ft == "typescriptreact" then
          return
        end
        require("lsp-format").on_attach(client, buf)
      end,
    })
  end,
}
