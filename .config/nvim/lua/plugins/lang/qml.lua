return {

  -- Add QML to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "qmljs", "qmldir" })
      end
    end,
  },

  -- Correctly setup lspconfig for QML🚀
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = {
          cmd = {
            "qmlls6",
          },
        },
      },
    },
  },
}
