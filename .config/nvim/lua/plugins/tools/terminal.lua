return {

  -- Enhanced neovim terminal
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        -- Size can be a number or a function which it is passed to the current terminal
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        hide_numbers = true,
        insert_mappings = false,
        terminal_mappings = false,
        direction = "horizontal", -- 'window' | 'float' | 'vertical' ,
        close_on_exit = true, -- Close the terminal window when the main process exits
        shade_terminals = false,
        shell = require("config").config.shell,
        float_opts = {
          border = "single",
          winblend = 3,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })
    end,
  },
}
