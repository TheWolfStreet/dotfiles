return {
    {
        "LazyVim/LazyVim",
        opts = { colorscheme = "kanagawa" },
    },
    {
        "rebelot/kanagawa.nvim",
        name = "kanagawa",
        opts = {
            background = {
                dark = "wave",
                light = "lotus",
            },
            colors = {
                theme = {
                    all = {
                        ui = {
                            bg_gutter = "none",
                        },
                    },
                },
            },
            overrides = function(colors)
                local theme = colors.theme
                return {
                    NormalFloat = { bg = "none" },
                    FloatBorder = { bg = "none" },
                    FloatTitle = { bg = "none" },

                    NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
                    LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
                    MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

                    TelescopeTitle = { fg = theme.ui.special, bold = true },
                    TelescopePromptNormal = { bg = theme.ui.bg_p1 },
                    TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
                    TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
                    TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
                    TelescopePreviewNormal = { bg = theme.ui.bg_dim },
                    TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
                    Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
                    PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
                    PmenuSbar = { bg = theme.ui.bg_m1 },
                    PmenuThumb = { bg = theme.ui.bg_p2 },
                }
            end,
        },
    },
    {
        "xiyaowong/transparent.nvim",
        enabled = true,
        lazy = false,
        config = function()
            local transparent = require("transparent")
            transparent.clear_prefix("NeoTree")
            transparent.clear_prefix("lualine_c")
            return {
                extra_groups = {
                    "NormalFloat",
                    "FloatBorder",
                    "FloatTitle",
                    "NormalDark",
                    "LazyNormal",
                    "MasonNormal",
                    "TabLine",
                    "TabLineFill",
                    "TabLineSel",
                    "TelescopeBorder",
                    "Pmenu",
                    "PmenuSbar",
                    "PmenuThumb",
                    "PmenuSel",
                    "WFFloatBorder",
                    "WFFloatBorderFocus",
                    "WFTheme",
                },
            }
        end,
    },
}
