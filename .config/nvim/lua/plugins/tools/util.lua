return {

  -- Library used by other plugins
  { "nvim-lua/plenary.nvim", lazy = true },

  {
    -- Neovim API completion sources
    "ii14/emmylua-nvim",
    lazy = true,
  },

  -- Measure startuptime
  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
    config = function()
      vim.g.startuptime_tries = 10
    end,
  },

  -- Session management. This saves your session in the background,
  -- keeping track of open buffers, window arrangement, and more.
  -- You can restore sessions when returning through the dashboard.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      plugins = { spelling = true },
      defaults = {
        {
          {
            mode = { "n", "v" },
            { "<leader><tab>", group = "tabs" },
            { "<leader>b", group = "buffer" },
            { "<leader>c", group = "code" },
            { "<leader>d", group = "debug" },
            { "<leader>dP", group = "more" },
            { "<leader>da", group = "adapters" },
            { "<leader>f", group = "file/find" },
            { "<leader>g", group = "git" },
            { "<leader>gh", group = "hunks" },
            { "<leader>q", group = "quit/session" },
            { "<leader>s", group = "search" },
            { "<leader>sn", group = "notifications" },
            { "<leader>u", group = "ui" },
            { "<leader>w", group = "windows" },
            { "<leader>x", group = "diagnostics/quickfix" },
            { "<localLeader>l", group = "vimtex" },
            { "=", group = "paste" },
            { "[", group = "prev" },
            { "]", group = "next" },
            { "g", group = "goto" },
            { "gs", group = "surround" },
            { "gz", group = "surrounding" },
            { "z", group = "folds" },
          },
        },
      },
      config = function(_, opts)
        local wk = require("which-key")
        wk.setup(opts)
      end,
    },

    -- Better diagnostics list and others
    {
      "folke/trouble.nvim",
      cmd = { "TroubleToggle", "Trouble" },
      opts = { use_diagnostic_signs = true },
    },

    -- Finds and lists all of the TODO, HACK, BUG, etc comment
    -- in your project and loads them into a browsable list.
    {
      "folke/todo-comments.nvim",
      cmd = { "TodoTrouble", "TodoTelescope" },
      event = { "BufReadPost", "BufNewFile" },
      config = true,
    },
  },
}
