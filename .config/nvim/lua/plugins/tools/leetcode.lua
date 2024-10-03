return {
  "kawre/leetcode.nvim",
  cmd = "Leet",
  build = ":TSUpdate html",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",

    "nvim-treesitter/nvim-treesitter",
    "rcarriga/nvim-notify",
    "kyazdani42/nvim-web-devicons",
  },
  opts = {},
}
