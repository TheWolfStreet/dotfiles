local au = vim.api.nvim_create_autocmd
local option = require("config").config.autocmd

-- Function to check if clipboard support is available
local function is_clipboard_supported()
  return vim.fn.has("clipboard") == 1
end

-- Function to copy text to the system clipboard
local function copy_to_clipboard(text)
  if is_clipboard_supported() then
    pcall(vim.fn.setreg, "+", text)
  end
end

-- Autocommand for toggling relative number
if option.relative_number then
  local rnu_group = vim.api.nvim_create_augroup("RNUGroup", { clear = true })

  au({ "InsertEnter" }, {
    group = rnu_group,
    pattern = { "*" },
    callback = function()
      vim.opt.rnu = false
    end,
  })

  au({ "InsertLeave" }, {
    group = rnu_group,
    pattern = { "*" },
    callback = function()
      if vim.fn.mode() ~= "i" then
        vim.opt.rnu = true
      end
    end,
  })
end

-- Autocommands for automatically entering insert mode in terminal buffers
if option.terminal_auto_insert then
  au({ "TermOpen", "TermEnter" }, { pattern = { "*" }, command = "startinsert" })
  au({ "WinEnter" }, { pattern = { "term://*toggleterm#*" }, command = "startinsert" })
end

-- Autocommand for handling yanked text
if option.highlight_yanked or option.copy_yanked_to_clipboard then
  local smart_yank_gid = vim.api.nvim_create_augroup("SmartYank", { clear = true })

  au("TextYankPost", {
    group = smart_yank_gid,
    desc = "Copy and highlight yanked text to system clipboard",
    callback = function()
      -- Highlight yanked text if highlight_yanked option is enabled
      if option.highlight_yanked then
        vim.highlight.on_yank({ higroup = "HighLightLineMatches", timeout = 200 })
      end

      -- Only copy to clipboard if the yank operation was triggered by 'y'
      ---@diagnostic disable-next-line: undefined-field
      if vim.v.operator == "y" then
        local present, yank_data = pcall(vim.fn.getreg, "0")
        if present and #yank_data > 0 then
          copy_to_clipboard(yank_data)
        end
      end
    end,
  })
end

-- Autocommands for showing/hiding the command line
if vim.opt.ch == 0 then
  au("CmdlineEnter", {
    pattern = "*",
    callback = function()
      vim.opt.ch = 1
    end,
  })

  au("CmdlineLeave", {
    pattern = "*",
    callback = function()
      vim.opt.ch = 0
    end,
  })
end

-- Autocommands for enabling/disabling cursorline
if option.cursorline then
  au({ "VimEnter", "WinEnter", "InsertLeave" }, {
    callback = function()
      vim.wo.cursorline = true
    end,
  })

  au({ "WinLeave", "InsertEnter" }, {
    callback = function()
      vim.wo.cursorline = false
    end,
  })
end
