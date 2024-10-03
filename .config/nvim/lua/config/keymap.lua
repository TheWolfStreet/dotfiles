local map_utils = require("libs.keymap")
local cmd = map_utils.wrap_cmd
local utility = require("libs.utils")

local function previous_trouble_quickfix_item()
  if require("trouble").is_open() then
    require("trouble").previous({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cprev)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end

local function next_trouble_quickfix_item()
  if require("trouble").is_open() then
    require("trouble").next({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cnext)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end

vim.g.mapleader = ";"

-- Define normal mode mappings
 -- stylua: ignore
map_utils.nmap({
  { "<C-z>", "u", desc = "Revert changes" },
  { "<", "<<", desc = "Decrease indent" },
  { ">", ">>", desc = "Increase indent" },
  { "<ESC>", cmd("noh"), desc = "Close search highlight" },
  { "<C-p>", [["+p]], desc = "Paste" },

 -- Todo Comments
 { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
 { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
 { "<leader>xt", cmd("TodoTrouble"), desc = "Todo (Trouble)" },
 { "<leader>xT", cmd("TodoTrouble keywords=TODO,FIX,FIXME"), desc = "Todo/Fix/Fixme (Trouble)" },
 { "<leader>st", cmd("TodoTelescope"), desc = "Todo" },
 { "<leader>sT", cmd("TodoTelescope keywords=TODO,FIX,FIXME"), desc = "Todo/Fix/Fixme" },

 -- Diagnostic list
 -- { "<leader>tx", cmd("TroubleToggle document_diagnostics"), desc = "Document Diagnostics (Trouble)" },
 -- { "<leader>tX", cmd("TroubleToggle workspace_diagnostics"), desc = "Workspace Diagnostics (Trouble)" },
 -- { "<leader>tL", cmd("TroubleToggle loclist"), desc = "Location List (Trouble)" },
 -- { "<leader>tQ", cmd("TroubleToggle quickfix"), desc = "Quickfix List (Trouble)" },
 { "[q", previous_trouble_quickfix_item, desc = "Previous trouble/quickfix item" },
 { "]q", next_trouble_quickfix_item, desc = "Next trouble/Quickfix item" },

 -- Neotree
 { "<leader>e", function() require("neo-tree.command").execute({ toggle = true, dir = utility.get_root() }) end, desc = "Explorer NeoTree (root dir)",},
 { "<leader>E", function() require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() }) end, desc = "Explorer NeoTree (cwd)",},

-- Persistence
-- { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
-- { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
-- { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },

-- Buffer management
{ "<leader>Q", function() require("libs.bufdel").delete_buffer_expr("", true) end, desc = "Delete Buffer (Force)" },
{ "<leader>q", function() require("libs.bufdel").delete_buffer_expr("", false) end, desc = "Delete Buffer" },
-- Save/Exit/Quit
{ "<leader>w", cmd("w!"), desc = "Save buffer" },
{ "<leader>x", cmd("x"), desc = "Save buffer and quit" },

-- Noicer UI
{ "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
{ "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
{ "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
{ "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },

  -- Terminal
  {"<leader>t", cmd("ToggleTerm dir=\"" .. utility.get_root() .. "\""), desc = "Terminal (root dir)"}
})

-- Define visual mode mappings
map_utils.xmap({
  { "<", "<gv", desc = "Increase indent" },
  { ">", ">gv", desc = "Decrease indent" },
})

-- Define insert mode mappings
map_utils.imap({
  { "<C-a>", "<ESC>^i", desc = "Jump to beginning of the line" },
  { "<C-e>", "<End>", desc = "Jump to end of the line" },
  { "<M-;>", "<ESC>", desc = "Exit insert mode" },
})

map_utils.tmap({
  -- Define terminal mode mappings
  { "<esc><esc>", "<c-\\><c-n>", desc = "Enter Normal Mode" },
  { "<C-h>", "<cmd>wincmd h<cr>", desc = "Go to left window" },
  { "<C-j>", "<cmd>wincmd j<cr>", desc = "Go to lower window" },
  { "<C-k>", "<cmd>wincmd k<cr>", desc = "Go to upper window" },
  { "<C-l>", "<cmd>wincmd l<cr>", desc = "Go to right window" },
  { "<C-/>", "<cmd>close<cr>", desc = "Hide Terminal" },
  { "<S-Space>", "<Space>" },
})
