return {
    {
        "nvim-lspconfig",
        opts = { inlay_hints = { enabled = false } },
    },
    { "folke/noice.nvim", enabled = true },
    { "rcarriga/nvim-notify", enabled = true },
    { "stevearc/dressing.nvim", enabled = true },
    { "nvim-pack/nvim-spectre", enabled = false },
    { "norcalli/nvim-colorizer.lua" },
    { "christoomey/vim-tmux-navigator" },
    { "f-person/git-blame.nvim" },
    { "ziontee113/color-picker.nvim", opts = {} },
    { "danymat/neogen", opts = {} },
    { "j-hui/fidget.nvim", opts = {} },
    -- Leetcode
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
    { "RaafatTurki/hex.nvim", lazy = true, event = { "BufReadPre" } },
}
