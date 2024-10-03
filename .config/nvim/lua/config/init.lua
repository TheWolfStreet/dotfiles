local M = {}

M.config = {
  vim_options = {
    completeopt = { "menuone", "noselect", "menu" }, -- Completion options
    termguicolors = true, -- Enable 24-bit RGB color in the TUI
    encoding = "utf-8", -- Set encoding to UTF-8
    fileencoding = "utf-8", -- Set file encoding to UTF-8
    number = true, -- Enable line numbers
    rnu = true, -- Disable relative line numbers
    expandtab = true, -- Expand tabs to spaces
    tabstop = 2, -- Set tab width to n spaces
    shiftwidth = 2, -- Set shift width to n spaces
    softtabstop = 2, -- Set soft tab stop to n spaces
    autoindent = true, -- Enable automatic indentation
    list = true, -- Enable display of listchars
    listchars = { tab = "> ", trail = "·" }, -- Set list characters
    scrolloff = 5, -- Set scroll offset to 5 lines
    timeoutlen = 800, -- Set timeout length to 800ms
    ttimeoutlen = 200, -- Set key sequence timeout length to 200ms
    timeout = true, -- Enable timeouts for mappings and key sequences
    viewoptions = { "cursor", "folds", "slash", "unix" }, -- Options for saving and restoring views
    wrap = true, -- Enable line wrapping
    tw = 0, -- Disable text width limit
    cindent = true, -- Enable C-style indentation
    splitright = true, -- Split windows to the right by default
    splitbelow = true, -- Split windows below by default
    showmode = false, -- Don't show mode text in command line
    showcmd = true, -- Show command in status line
    wildmenu = true, -- Enable command-line completion menu
    ignorecase = true, -- Ignore case when searching
    smartcase = true, -- Override 'ignorecase' when search pattern has uppercase characters
    inccommand = "split", -- Show the effects of a command incrementally, as it's typed.
    ttyfast = true, -- Assume fast terminal connection.
    visualbell = true, -- Use visual bell (flashes) instead of an audible bell.
    updatetime = 100, -- Time (in ms) to wait before writing swap file after a change.
    virtualedit = "block", -- Allow cursor to move where there is no actual character (for block operations).
    signcolumn = "yes:1", -- Always show the signcolumn, enough for one sign.
    mouse = "a", -- Enable mouse in all modes.
    foldmethod = "indent", -- Use indentation level as a folding method.
    foldlevel = 99, -- Open most folds by default.
    foldenable = true, -- Enable folding.
    formatoptions = "qj", -- Automatically format comments and join lines.
    hidden = true, -- Allow buffer changes to be hidden in the background.
    ch = 0, -- Set command-line height to minimal for more compatibility with UI.
    fillchars = { eob = " " }, -- Hide the '~' empty space symbol
    shortmess = "aTWF", -- Abbreviate and truncate various messages.
    -- 1. "a": Use all abbreviations, such as truncate "Modified" to "[+]"
    -- 2. "T": Truncate file message in the middle if it is too long
    -- 3. "W": Do not show "written" or "[w]" when writing a file
    -- 4. "F": Do not show file info when editing a file
  },
  transparent = true, -- Style for transparent (blurry) terminal emulator
  icons = {
    dap = {
      Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
      Breakpoint = " ",
      BreakpointCondition = " ",
      BreakpointRejected = { " ", "DiagnosticError" },
      LogPoint = ".>",
    },
    diagnostics = {
      Error = " ",
      Warn = " ",
      Hint = " ",
      Info = " ",
    },
    git = {
      added = " ",
      modified = " ",
      removed = " ",
    },
    kinds = {
      Array = " ",
      Boolean = " ",
      Class = " ",
      Color = " ",
      Constant = " ",
      Constructor = " ",
      Copilot = " ",
      Enum = " ",
      EnumMember = " ",
      Event = " ",
      Field = " ",
      File = " ",
      Folder = " ",
      Function = " ",
      Interface = " ",
      Key = " ",
      Keyword = " ",
      Method = " ",
      Module = " ",
      Namespace = " ",
      Null = " ",
      Number = " ",
      Object = " ",
      Operator = " ",
      Package = " ",
      Property = " ",
      Reference = " ",
      Snippet = " ",
      String = " ",
      Struct = " ",
      Text = " ",
      TypeParameter = " ",
      Unit = " ",
      Value = " ",
      Variable = " ",
    },
  },
  autocmd = {
    relative_number = true,
    terminal_auto_insert = true,
    highlight_yanked = true,
    copy_yanked_to_clipboard = true,
  },
  shell = "/bin/zsh", -- Terminal shell
}

M.opts = {
  performance = {
    rtp = {
      -- Disable vim builtin plugins
      disabled_plugins = {
        "gzip",
        "zip",
        "zipPlugin",
        "tar",
        "tarPlugin",
        "getscript",
        "getscriptPlugin",
        "vimball",
        "vimballPlugin",
        "2html_plugin",
        "matchit",
        "matchparen",
        "logiPat",
        "rust_vim",
        "rust_vim_plugin_cargo",
        "rrhelper",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "editorconfig",
        "man",
        "rplugin",
        "nvim",
        "spellfile",
        "tutor",
        "tohtml",
        "shada",
        "health",
      },
    },
  },
}

local disable_builtin_provider = {
  "perl",
  "node",
  "ruby",
  "python",
  "python3",
}

for _, provider in ipairs(disable_builtin_provider) do
  vim.g["loaded_" .. provider .. "_provider"] = 1
end

local function ensure_cache(suffix)
  local cache_dir = vim.fn.stdpath("cache")
  local dir = cache_dir .. "/" .. suffix
  local stat = vim.loop.fs_stat(dir)

  if stat == nil then
    vim.fn.mkdir(dir, "p")
  end

  return dir
end

local backup_dir, undo_dir, has_persist
backup_dir, undo_dir, has_persist =
  ensure_cache("backup"), ensure_cache("undo"), vim.fn.has("persistent_undo")

if backup_dir then
  M.config.vim_options.backupdir, M.config.vim_options.directory = backup_dir, backup_dir
end
-- Persistent undo
if has_persist == 1 then
  M.config.vim_options.undofile, M.config.vim_options.undodir = true, undo_dir
end
-- Load options
for option, value in pairs(M.config.vim_options) do
  vim.opt[option] = value
end

vim.cfg = M.config.vim_options
return M
