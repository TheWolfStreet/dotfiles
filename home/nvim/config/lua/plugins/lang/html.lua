return {
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
            local custom_data = vim.fn.stdpath("config") .. "/tailwindcss-data.json"
            local custom_data_uri = vim.uri_from_fname(custom_data)

            opts.servers = opts.servers or {}
            opts.servers.html = opts.servers.html or {}
            opts.servers.cssls = vim.tbl_deep_extend("force", opts.servers.cssls or {}, {
                settings = {
                    css = {
                        customData = { custom_data, custom_data_uri },
                    },
                    scss = {
                        customData = { custom_data, custom_data_uri },
                    },
                    less = {
                        customData = { custom_data, custom_data_uri },
                    },
                },
            })
        end,
    },
}
