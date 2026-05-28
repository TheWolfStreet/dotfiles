local opt = vim.opt
local g = vim.g

local function prepend_path(dir)
	if vim.fn.isdirectory(dir) == 0 then return end
	local path = vim.env.PATH or ""
	for part in string.gmatch(path, "[^:]+") do
		if part == dir then return end
	end
	vim.env.PATH = dir .. ":" .. path
end

prepend_path("/etc/profiles/per-user/" .. (vim.env.USER or "") .. "/bin")
prepend_path("/run/current-system/sw/bin")

opt.wrap = true
opt.conceallevel = 1
opt.cursorline = false
opt.number = true
opt.relativenumber = true
opt.hlsearch = false
opt.incsearch = true
opt.scrolloff = 4
opt.clipboard = "unnamedplus"
opt.breakindent = true
opt.inccommand = "split"

g.python_recommended_style = 0
g.rust_recommended_style = 0
opt.expandtab = false
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 0

vim.g.snacks_animate_scroll = false

opt.swapfile = false
opt.cinoptions:append(":0")
