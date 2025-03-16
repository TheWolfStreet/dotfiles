local km = vim.keymap.set

km("n", "Q", "@q")

-- Telescope
km("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "[F]ind in file using Telescope" })
km("n", "<leader>fc", "<nop>")
km(
    "n",
    "<leader><leader>",
    function() require("telescope.builtin").find_files(require("telescope.themes").get_dropdown({ previewer = false })) end,
    { desc = "Telescope [f]ind file" }
)

-- Toggle inlay hints
km(
    "n",
    "<Leader>cH",
    function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end,
    { desc = "Toggle Inlay Hints" }
)

-- Move selected lines
km("v", "J", ":m '>+1<CR>gv=gv")
km("v", "K", ":m '<-2<CR>gv=gv")

-- Diagnostics
km("n", "<leader>xx", vim.cmd.TroubleToggle, { desc = "TroubleToggle" })
km("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", { desc = "TroubleToggle [W]orkspace" })

-- Buffers
km({ "n", "i", "v" }, "<A-l>", vim.cmd.bnext, { desc = "Switch to next Buffer" })
km({ "n", "i", "v" }, "<A-h>", vim.cmd.bprev, { desc = "Switch to prev Buffer" })
km("n", "<C-q>", function() vim.cmd("bw") end, { desc = "Close Buffer" })

-- Selection
km("n", "<C-a>", "ggVG")
km("v", "V", "j")

-- Paste
km("n", "<leader>p", '"_dP')

-- Colors
km("n", "<leader>ct", vim.cmd.ColorizerToggle, { desc = "[C]olorizer" })
km("n", "<leader>cp", vim.cmd.PickColor, { desc = "[P]ick Color" })

-- Generate docs
km("n", "<Leader>dg", require("neogen").generate, { desc = "Generate Docs" })

-- Tmux
km({ "n", "i", "v" }, "<C-h>", vim.cmd.TmuxNavigateLeft)
km({ "n", "i", "v" }, "<C-j>", vim.cmd.TmuxNavigateDown)
km({ "n", "i", "v" }, "<C-k>", vim.cmd.TmuxNavigateUp)
km({ "n", "i", "v" }, "<C-l>", vim.cmd.TmuxNavigateRight)

-- Tranparency
km("n", "<leader>o", function() vim.cmd("TransparentToggle") end)
