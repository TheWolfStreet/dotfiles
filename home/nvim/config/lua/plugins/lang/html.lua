return {
    -- LazyVim doesn't ship an `extras.lang.html` module.
    -- Keep HTML/CSS support here explicitly.
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "html",
                "css",
                "scss",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            -- These servers are typically provided by `vscode-langservers-extracted`.
            opts.servers.html = opts.servers.html or {}
            opts.servers.cssls = opts.servers.cssls or {}
        end,
    },
}
