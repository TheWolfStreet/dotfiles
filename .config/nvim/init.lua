local config = require("config")
local notify = require("libs.notify")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  notify.info("The package manager lazy.nvim is not detected, initiating installation...")
  local success, error = pcall(vim.fn.system, {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if not success then
    notify.error("Installation of plugin manager lazy.nvim was unsuccessful!", error)
    notify.info("You can remove the plugin manager's directory [" .. lazypath .. "] and retry")
    return
  end
end

vim.opt.rtp:prepend(lazypath)

require("config.keymap")
require("config.autocmd")
require("lazy").setup("plugins", config.opts)
