local km = vim.keymap.set

km("n", "Q", "@q")

km("x", "<leader>p", '"_dP', { desc = "Paste without replacing register" })
km("n", "<C-q>", function() Snacks.bufdelete() end, { desc = "Delete Buffer" })
km("n", "<leader>ct", "<cmd>ColorizerToggle<cr>", { desc = "Toggle Colorizer" })
km("n", "<leader>uP", "<cmd>PickColor<cr>", { desc = "Pick Color" })
km("n", "<leader>cn", function() require("neogen").generate() end, { desc = "Generate Annotations" })

km("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Navigate Left (tmux)" })
km("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Navigate Down (tmux)" })
km("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Navigate Up (tmux)" })
km("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Navigate Right (tmux)" })

require("snacks")
    .toggle({
        name = "Transparency",
        get = function() return vim.g.transparent_enabled end,
        set = function(state)
            if state ~= vim.g.transparent_enabled then vim.cmd("TransparentToggle") end
        end,
    })
    :map("<leader>ut", { desc = "Toggle transparency" })
