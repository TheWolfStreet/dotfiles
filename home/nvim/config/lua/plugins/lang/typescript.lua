return {
    { "nvim-mini/mini.icons" },
    -- { import = "lazyvim.plugins.extras.lang.astro" },
    -- { import = "lazyvim.plugins.extras.lang.vue" },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                javascript = { "prettier" },
                typescript = { "prettier" },
                typescriptreact = { "prettier" },
                javascriptreact = { "prettier" },
                ["typescript.jsx"] = { "prettier" },
                ["javascript.jsx"] = { "prettier" },
                css = { "prettier" },
                scss = { "prettier" },
                json = { "prettier" },
                -- astro = { "prettier" },
                svelte = { "prettier" },
                vue = { "prettier" },
                graphql = { "prettier" },
                yaml = { "prettier" },
            },
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "typescript",
                "javascript",
                "jsdoc",
                "vue",
                "svelte",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}

            local tailwind = opts.servers.tailwindcss or {}

            local prev_before_init = tailwind.before_init

            local function resolve_tailwind_v4_config(root_dir)
                local candidates = {
                    "src/app.css",
                    "src/routes/layout.css",
                    "app.css",
                }

                for _, rel_path in ipairs(candidates) do
                    if vim.fn.filereadable(root_dir .. "/" .. rel_path) == 1 then return rel_path end
                end

                return nil
            end

            tailwind.before_init = function(params, config)
                if prev_before_init then prev_before_init(params, config) end
                local config_file = config.root_dir and resolve_tailwind_v4_config(config.root_dir)

                if config_file then
                    config.settings = config.settings or {}
                    config.settings.tailwindCSS = config.settings.tailwindCSS or {}
                    config.settings.tailwindCSS.experimental =
                        vim.tbl_deep_extend("force", config.settings.tailwindCSS.experimental or {}, {
                            configFile = config_file,
                        })
                end
            end

            tailwind.settings = vim.tbl_deep_extend("force", tailwind.settings or {}, {
                tailwindCSS = {
                    includeLanguages = {
                        svelte = "html",
                    },
                    classFunctions = { "clsx", "cn", "cva" },
                },
            })

            opts.servers.tailwindcss = tailwind
        end,
    },
    {
        "themaxmarchuk/tailwindcss-colors.nvim",
        opts = {},
    },
}
