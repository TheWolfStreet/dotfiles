local opt = vim.opt
local g = vim.g

opt.wrap = true
opt.conceallevel = 1
opt.cursorline = false
opt.number = true -- Print line number
opt.relativenumber = true -- Relative line numbers
opt.hlsearch = false -- Highlight search
opt.incsearch = true -- Incremental search
opt.scrolloff = 4 -- Scroll offset
opt.clipboard = "unnamedplus" -- Sync clipboard with os
opt.breakindent = true
opt.inccommand = "split"

g.python_recommended_style = 0
g.rust_recommended_style = 0
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = false

vim.g.snacks_animate_scroll = false -- Disable scroll animations

opt.swapfile = false
opt.cinoptions:append(":0") -- Switch statement indentations
