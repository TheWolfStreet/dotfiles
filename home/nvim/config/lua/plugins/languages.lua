return {
    {
        "mason-org/mason.nvim",
        enabled = vim.fn.executable("nix") == 0,
    },
    {
        "mason-org/mason-lspconfig.nvim",
        enabled = vim.fn.executable("nix") == 0,
    },

    { import = "plugins.lang" },

    {
        "saghen/blink.cmp",
        opts = {
            keymap = {
                ["<C-space>"] = false,
                ["<C-x><C-o>"] = { "show", "show_documentation", "hide_documentation" },
            },
        },
    },

    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                c = { "clang_format" },
                cpp = { "clang_format" },
                xml = { "xmllint" },
            },
        },
    },
}
