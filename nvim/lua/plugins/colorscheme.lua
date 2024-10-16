local transparent = true

return {
    { "Mofiqul/vscode.nvim" },
    { "Mofiqul/adwaita.nvim" },
    { "nyoom-engineering/oxocarbon.nvim" },
    { "rose-pine/neovim" },
    { "navarasu/onedark.nvim" },
    { "projekt0n/github-nvim-theme" },
    {
        "LazyVim/LazyVim",
        opts = { colorscheme = "kanagawa" },
    },
    {
        "rebelot/kanagawa.nvim",
        name = "kanagawa",
        opts = {
            transparent = transparent,
            colors = {
                theme = {
                    all = {
                        ui = {
                            bg_gutter = transparent and "none" or nil,
                        },
                    },
                },
            },
            overrides = function(colors)
                local theme = colors.theme
                if transparent then
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
                    return {
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
                end
            end,
        },
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        opts = {
            transparent_background = transparent,
            flavour = "mocha",
            color_overrides = {
                mocha = {
                    red = "#e55f86",
                    green = "#00D787",
                    peach = "#EBFF71",
                    blue = "#50a4e7",
                    mauve = "#9076e7",
                    sky = "#50e6e6",
                    pink = "#e781d6",

                    maroon = "#d15577",
                    teal = "#43c383",
                    yellow = "#d8e77b",
                    lavender = "#4886c8",
                    flamingo = "#8861dd",
                    sapphire = "#43c3c3",
                    rosewater = "#d76dc5",

                    text = "#e7e7e7",
                    subtext1 = "#dbdbdb",
                    subtext2 = "#cacaca",

                    overlay2 = "#b2b5b3",
                    overlay1 = "#a8aba9",
                    overlay0 = "#9ea19f",

                    surface2 = "#353331",
                    surface1 = "#2f2e2d",
                    surface0 = "#2c2a2a",

                    base = "#171717",
                    mantle = "#111111",
                    crust = "#0a0a0a",
                },
                latte = {
                    base = "#fffffa",
                    mantle = "#e7e8e9",
                    crust = "#d3d4d5",
                },
            },
        },
    },
}
