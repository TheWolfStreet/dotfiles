return {
  -- Add NASM to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "nasm", "asm" })
      end
    end,
  },

  -- Setup lspconfig for nasm-lsp
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Ensure mason installs the server
        asm_lsp = {
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("Makefile", "*.asm", "*.nasm")(fname)
              or require("lspconfig.util").find_git_ancestor(fname)
          end,
          cmd = {
            "asm-lsp",
          },
        },
      },
    },
  },
}
