---@type LazySpec
return {
  {
    "ggandor/leap.nvim",
    url = "https://codeberg.org/andyg/leap.nvim",
  },
  {
    "ggandor/flit.nvim",
    dependencies = {
      {
        "ggandor/leap.nvim",
        url = "https://codeberg.org/andyg/leap.nvim",
      },
    },
  },
}
