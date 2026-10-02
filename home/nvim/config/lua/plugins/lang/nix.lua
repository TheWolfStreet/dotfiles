return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.nil_ls = { enabled = false }
            local nixd = opts.servers.nixd or {}
            nixd.settings = nixd.settings or {}
            local previous = nixd.before_init
            nixd.before_init = function(params, config)
                if previous then previous(params, config) end
                local path = vim.env.NVIM_NIXD_DOTFILES
                local host = vim.env.NVIM_NIXD_HOST
                if not path or not host or config.root_dir ~= path then return end

                local options = "(builtins.getFlake "
                    .. vim.json.encode(path)
                    .. ").nixosConfigurations."
                    .. vim.json.encode(host)
                    .. ".options"
                config.settings = config.settings or {}
                config.settings.nixd = config.settings.nixd or {}
                config.settings.nixd.options = vim.tbl_deep_extend("force", config.settings.nixd.options or {}, {
                    nixos = { expr = options },
                    ["home-manager"] = { expr = options .. ".home-manager.users.type.getSubOptions []" },
                })
            end
            opts.servers.nixd = nixd
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = { formatters_by_ft = { nix = { "alejandra" } } },
    },
}
