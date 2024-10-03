return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "svelte" })
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        svelte = function(_, opts)
          local sv = require("lspconfig.server_configurations.svelte")
          --- @param ft string
          opts.filetypes = vim.tbl_filter(function(ft)
            return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
          end, sv.default_config.filetypes)
        end,
      },
    },
  },
}
