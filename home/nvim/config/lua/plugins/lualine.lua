local icons = require("lazyvim.config").icons

local diff = {
    "diff",
    symbols = {
        added = icons.git.added,
        modified = icons.git.modified,
        removed = icons.git.removed,
    },
    source = function()
        local signs = vim.b.gitsigns_status_dict
        if signs then return { added = signs.added, modified = signs.changed, removed = signs.removed } end
    end,
}

local diagnostic = {
    "diagnostics",
    symbols = {
        error = icons.diagnostics.Error,
        warn = icons.diagnostics.Warn,
        info = icons.diagnostics.Info,
        hint = icons.diagnostics.Hint,
    },
}

local filename = {
    "filename",
    path = 1,
    symbols = {
        modified = " ",
        readonly = "[ro]",
        unnamed = "[unnamed]",
        newfile = "[new]",
    },
}

local position = {
    "location",
    padding = { left = 1, right = 1 },
}

return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = function()
            return {
                options = {
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                    theme = "auto",
                    globalstatus = true,
                    disabled_filetypes = { statusline = { "dashboard", "alpha" } },
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", diff },
                    lualine_c = { LazyVim.lualine.root_dir({ cwd = true }), filename, diagnostic },
                    lualine_x = { "searchcount", "selectioncount", "encoding", "filetype" },
                    lualine_y = {},
                    lualine_z = { position },
                },
            }
        end,
    },
}
