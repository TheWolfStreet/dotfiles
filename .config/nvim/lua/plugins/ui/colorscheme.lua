local config = require("config").config

return {
  -- Color scheme
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    config = function()
      require("kanagawa").setup({
        terminalColors = true,
        transparent = config.transparent,
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = { bold = true },
        keywordStyle = { italic = true },
        statementStyle = { bold = true },
        typeStyle = { bold = true },
        variablebuiltinStyle = { italic = true },
        globalStatus = true,
        overrides = function(colors)
          local theme = colors.theme
          if config.transparent then
            return {
              NormalFloat = { bg = "none" },
              FloatBorder = { bg = "none" },
              FloatTitle = { bg = "none" },
              NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
              LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
              MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
              StatusLine = { bg = "none", ctermbg = "none" },
              StatusLineNC = { bg = "none", ctermbg = "none" },
              TabLine = { bg = "none", ctermbg = "none" },
              TabLineFill = { bg = "none", ctermbg = "none" },
              TabLineSel = { bg = "none", ctermbg = "none" },
              TelescopeBorder = { bg = "none", ctermbg = "none" },
              Pmenu = { bg = "none", ctermbg = "none" },
              PmenuSbar = { bg = "none", ctermbg = "none" },
              PmenuThumb = { bg = "none", ctermbg = "none" },
              PmenuSel = { bg = "none", ctermbg = "none" },
              WFFloatBorder = { bg = "none", ctermbg = "none" },
              WFFloatBorderFocus = { bg = "none", ctermbg = "none" },
              WFTheme = { bg = "none", ctermbg = "none" },
            }
          else
            return {}
          end
        end,
        colors = {
          theme = {
            all = {
              ui = {
                bg_gutter = "none",
              },
            },
          },
        },
      })

      require("kanagawa").load("wave")
    end,
  },
}
