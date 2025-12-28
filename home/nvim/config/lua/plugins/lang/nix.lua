return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = { ensure_installed = { "nix" } },
    },
    {
        "neovim/nvim-lspconfig",
        opts = { servers = { nixd = {} } },
    },
    {
        "stevearc/conform.nvim",
        opts = { formatters_by_ft = { nix = { "alejandra" } } },
    },
}
