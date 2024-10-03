return {

  -- Add C# to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "c_sharp" })
      end
    end,
  },

  -- Correctly setup lspconfig for csharp_ls 🚀
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Ensure mason installs the server
        csharp_ls = {
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern(".sln", ".csproj")(fname)
              or require("lspconfig.util").find_git_ancestor(fname)
          end,
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          cmd = {
            "csharp-ls",
          },
        },
      },
    },
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      -- Ensure C# debugger is installed
      "williamboman/mason.nvim",
      optional = true,
      opts = function(_, opts)
        if type(opts.ensure_installed) == "table" then
          vim.list_extend(opts.ensure_installed, { "netcoredbg" })
        end
      end,
    },
    opts = function()
      local dap = require("dap")
      ---@class dap.adapters
      dap.adapters = dap.adapters or {}
      if not dap.adapters.netcoredbg then
        dap.adapters.netcoredbg = {
          type = "executable",
          command = "netcoredbg",
          args = { "--interpreter=vscode" },
        }
      end
      ---@class dap.configurations
      dap.configurations = dap.configurations or {}
      dap.configurations.cs = {
        {
          name = "Debug .NET Core DLL",
          type = "netcoredbg",
          request = "launch",
          program = function()
            ---@diagnostic disable-next-line: redundant-parameter
            return vim.fn.input("Path to DLL: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
          end,
        },
      }
    end,
  },
}
