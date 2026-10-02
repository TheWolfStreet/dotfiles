return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                json = { "prettier" },
                jsonc = { "prettier" },
                json5 = { "prettier" },
            },
        },
    },

    {
        "nvim-treesitter/nvim-treesitter",
        opts = { ensure_installed = { "json5" } },
    },
}
