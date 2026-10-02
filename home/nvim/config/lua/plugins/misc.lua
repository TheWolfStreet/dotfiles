return {
    {
        "nvim-lspconfig",
        opts = { inlay_hints = { enabled = false } },
    },
    { "folke/noice.nvim", enabled = true },
    { "nvim-pack/nvim-spectre", enabled = false },
    { "norcalli/nvim-colorizer.lua" },
    { "christoomey/vim-tmux-navigator" },
    {
        "f-person/git-blame.nvim",
        cmd = {
            "GitBlameEnable",
            "GitBlameDisable",
            "GitBlameToggle",
            "GitBlameCopySHA",
            "GitBlameCopyCommitURL",
            "GitBlameCopyFileURL",
            "GitBlameCopyPRURL",
            "GitBlameOpenCommitURL",
            "GitBlameOpenFileURL",
        },
        init = function() vim.g.gitblame_enabled = false end,
    },
    { "ziontee113/color-picker.nvim", opts = {} },
    { "danymat/neogen", opts = {} },
    {
        "kawre/leetcode.nvim",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
        },
        opts = {
            lang = "cpp",
        },
    },
    {
        "RaafatTurki/hex.nvim",
        cmd = { "HexDump", "HexAssemble", "HexToggle" },
        opts = {
            is_file_binary_pre_read = function() return false end,
            is_file_binary_post_read = function() return false end,
        },
    },
}
