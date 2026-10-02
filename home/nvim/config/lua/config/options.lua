local opt = vim.opt

local function append_path(dir)
    if vim.fn.isdirectory(dir) == 0 then return end
    local path = vim.env.PATH or ""
    for part in string.gmatch(path, "[^:]+") do
        if part == dir then return end
    end
    vim.env.PATH = path .. ":" .. dir
end

append_path("/etc/profiles/per-user/" .. (vim.env.USER or "") .. "/bin")
append_path("/run/current-system/sw/bin")

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

opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = -1

vim.g.snacks_animate_scroll = false

opt.swapfile = false
opt.cinoptions:append(":0")
