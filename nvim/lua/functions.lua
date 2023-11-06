G = {}

function G.reload()
  dofile(vim.fn.expand('~/.config/nvim/init.lua'))
  print("reloaded")
end

return G
