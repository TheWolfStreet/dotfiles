return {
    { "catppuccin/nvim", enabled = false },
    { "tokyonight.nvim", enabled = false },
    {
        "LazyVim/LazyVim",
        opts = { colorscheme = "kanagawa" },
    },
    {
        "rebelot/kanagawa.nvim",
        name = "kanagawa",
        config = function()
            local function find_gsettings()
                local bin = vim.fn.exepath("gsettings")
                if bin ~= "" then return bin end

                local fallback = "/run/current-system/sw/bin/gsettings"
                if vim.fn.executable(fallback) == 1 then return fallback end

                return nil
            end

            local function gsettings_get(bin, key)
                local value = vim.fn.system({
                    bin,
                    "get",
                    "org.gnome.desktop.interface",
                    key,
                })

                if vim.v.shell_error ~= 0 then return nil end

                return vim.trim(value)
            end

            local function detect_background()
                local gsettings = find_gsettings()
                if not gsettings then return nil end

                local color_scheme = gsettings_get(gsettings, "color-scheme")
                if color_scheme == "'prefer-dark'" then return "dark" end
                if color_scheme == "'prefer-light'" then return "light" end

                local gtk_theme = gsettings_get(gsettings, "gtk-theme")
                if gtk_theme then
                    if gtk_theme:lower():find("dark", 1, true) then return "dark" end

                    return "light"
                end

                return nil
            end

            local background = detect_background()
            if background then vim.opt.background = background end

            require("kanagawa").setup({
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
            })

            vim.cmd("colorscheme kanagawa")
        end,
    },
    {
        "folke/snacks.nvim",
        lazy = false,
        opts = {
            explorer = { enabled = true },
            dashboard = { enabled = false },
            indent = {
                indent = {
                    hl = "LineNr",
                    char = "┊",
                },
                scope = {
                    hl = "SnacksIndent",
                },
            },
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
