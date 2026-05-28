return {
    { "nvim-mini/mini.icons" },
    { "roobert/tailwindcss-colorizer-cmp.nvim", opts = {} },
    { import = "lazyvim.plugins.extras.linting.eslint" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    -- { import = "lazyvim.plugins.extras.lang.astro" },
    { import = "lazyvim.plugins.extras.lang.svelte" },
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

            local prev_on_new_config = tailwind.on_new_config

            local function resolve_tailwind_v4_config(root_dir)
                local candidates = {
                    "src/app.css",
                    "src/routes/layout.css",
                    "app.css",
                }

                for _, rel_path in ipairs(candidates) do
                    if vim.fn.filereadable(root_dir .. "/" .. rel_path) == 1 then
                        return rel_path
                    end
                end

                return nil
            end

            tailwind.on_new_config = function(new_config, new_root_dir)
                if prev_on_new_config then
                    prev_on_new_config(new_config, new_root_dir)
                end

                local config_file = resolve_tailwind_v4_config(new_root_dir)

                if config_file then
                    new_config.settings = new_config.settings or {}
                    new_config.settings.tailwindCSS = new_config.settings.tailwindCSS or {}
                    new_config.settings.tailwindCSS.experimental = vim.tbl_deep_extend(
                        "force",
                        new_config.settings.tailwindCSS.experimental or {},
                        {
                            configFile = config_file,
                        }
                    )
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
