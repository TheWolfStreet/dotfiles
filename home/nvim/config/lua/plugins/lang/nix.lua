return {
    { import = "lazyvim.plugins.extras.lang.nix" },
    {
        "neovim/nvim-lspconfig",
        opts = { servers = { nixd = {} } },
    },
    {
        "stevearc/conform.nvim",
        opts = { formatters_by_ft = { nix = { "alejandra" } } },
    },
}
