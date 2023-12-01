local ok, ls = pcall(require, "luasnip")
if not ok then
	return
end

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmt = require("luasnip.extras.fmt").fmt
local types = require("luasnip.util.types")

ls.add_snippets("ruby", {
  s("spec", fmt([[
  # frozen_string_literal: true

  require 'spec_helper'

  RSpec.describe {} do

  end
  ]], {
    i(1, "ClassName")
  })),
  s({
      trig = "frozen",
      name = "Frozen String Literal",
      desc = "Add the frozen string literal to the top of the file"
    },
    fmt([[
    # frozen_string_literal: true
    {}
    ]], {i(1)})
  )
})
