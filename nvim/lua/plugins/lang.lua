local function uname()
    local handle = io.popen("uname")
    if handle then
        local res = handle:read("a")
        handle:close()
        return string.match(res, "^%s*(.-)%s*$")
    end
    return nil
end

return {
    {

        "jay-babu/mason-nvim-dap.nvim",
        -- enable in containers and Mac, but not NixOS
        enabled = io.open("/run/.containerenv", "r") ~= nil or uname() == "Darwin",
    },
    {
        "williamboman/mason.nvim",
        -- enable in containers and Mac, but not NixOS
        enabled = io.open("/run/.containerenv", "r") ~= nil or uname() == "Darwin",
        opts = {
            PATH = "append",
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "lua",
                "rust",
                "cpp",
                "svelte",
                "go",
                "nix",
                "bash",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                nil_ls = {},
                lua_ls = {},
                bashls = {},

                denols = {
                    root_dir = require("lspconfig").util.root_pattern("deno.json"),
                },

                cssls = {},
                svelte = {},
                tailwindcss = {},
                cssmodules_ls = {},
                eslint = {},
                vala_ls = {},
                mesonlsp = {},
                taplo = {},
            },
        },
    },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                nix = { "alejandra" },
            },
        },
    },
}
