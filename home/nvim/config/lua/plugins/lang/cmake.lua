return {
    {
        "stevearc/conform.nvim",
        optional = true,
        opts = {
            formatters_by_ft = {
                cmake = { "cmake_format" },
            },
        },
    },
    {
        "mfussenegger/nvim-lint",
        optional = true,
        opts = {
            linters_by_ft = {
                cmake = { "cmakelint" },
            },
        },
    },
}
