-- Bufferline and Statusline
return {
  {
    "rebelot/heirline.nvim",
    event = "UIEnter",
    dependencies = {
      "SmiteshP/nvim-navic",
      "kyazdani42/nvim-web-devicons",
    },
    config = function()
      local conditions = require("heirline.conditions")
      local heirline_util = require("heirline.utils")
      local Util = require("lazy.core.util")

      local colors = {
        bg = "#000000",
        fg = "#FFFFFF",
        black = "#000000",
        yellow = "#E5C07B",
        cyan = "#70C0BA",
        dimblue = "#83A598",
        green = "#98C379",
        orange = "#FF9E3B",
        purple = "#C678DD",
        magenta = "#D27E99",
        blue = "#81A1C1",
        red = "#D54E53",
      }

      local ViMode = {
        init = function(self)
          self.mode = vim.fn.mode(1) -- :h mode()
        end,
        static = {
          mode_names = {
            n = " NORMAL",
            no = " OPERATOR-PENDING",
            nov = " OPERATOR-PENDING CHARWISE",
            noV = " OPERATOR-PENDING LINEWISE",
            ["no\22"] = " OPERATOR-PENDING BLOCKWISE",
            niI = " NORMAL-INSERT",
            niR = " NORMAL-REPLACE",
            niV = " NORMAL-VIRTUAL REPLACE",
            nt = " NORMAL-TERMINAL",
            v = "󰇀 VISUAL",
            vs = "󰇀 VISUAL SELECT",
            V = "󰇀 VISUAL LINE",
            Vs = "󰇀 VISUAL LINE SELECT",
            ["\22"] = "󰇀 VISUAL BLOCK",
            ["\22s"] = "󰇀 VISUAL BLOCK SELECT",
            s = "󰆾 SELECT",
            S = "󰆾 SELECT LINE",
            ["\19"] = "󰆾 SELECT BLOCK",
            i = " INSERT",
            ic = " INSERT COMPLETION",
            ix = " INSERT CTRL-X COMPLETION",
            R = " REPLACE",
            Rc = " REPLACE COMPLETION",
            Rx = " REPLACE CTRL-X COMPLETION",
            Rv = " VIRTUAL REPLACE",
            Rvc = " VIRTUAL REPLACE COMPLETION",
            Rvx = " VIRTUAL REPLACE CTRL-X COMPLETION",
            c = " COMMAND",
            cv = " VIM EX",
            r = " HIT-ENTER",
            rm = "󰍻 MORE",
            ["r?"] = "󰍻 CONFIRM",
            ["!"] = " SHELL",
            t = " TERMINAL",
          },
          mode_colors = {
            n = colors.yellow,
            no = colors.yellow,
            nov = colors.yellow,
            noV = colors.yellow,
            ["no\22"] = colors.yellow,
            niI = colors.yellow,
            niR = colors.yellow,
            niV = colors.yellow,
            nt = colors.yellow,
            v = colors.blue,
            vs = colors.blue,
            V = colors.blue,
            Vs = colors.blue,
            ["\22"] = colors.blue,
            ["\22s"] = colors.blue,
            s = colors.orange,
            S = colors.orange,
            ["\19"] = colors.orange,
            i = colors.green,
            ic = colors.green,
            ix = colors.green,
            R = colors.purple,
            Rc = colors.purple,
            Rx = colors.purple,
            Rv = colors.purple,
            Rvc = colors.purple,
            Rvx = colors.purple,
            c = colors.magenta,
            cv = colors.magenta,
            r = colors.cyan,
            rm = colors.cyan,
            ["r?"] = colors.cyan,
            ["!"] = colors.red,
            t = colors.yellow,
          },
        },

        -- Output mode name if exists
        provider = function(self)
          if self.mode_names[self.mode] then
            return "%2(" .. self.mode_names[self.mode] .. "%) "
          else
            Util.warn("Missing mode name: " .. self.mode, { title = "Heirline" })
            return ""
          end
        end,

        -- Same goes for the highlight. Now the foreground will change according to the current mode.
        hl = function(self)
          local mode = self.mode:sub(1, 1) -- Get only the first mode character
          return { fg = self.mode_colors[mode], bold = true }
        end,
        -- Re-evaluate the component only on ModeChanged event!
        -- Also allows the statusline to be re-evaluated when entering operator-pending mode
        update = {
          "ModeChanged",
          pattern = "*:*",
          callback = vim.schedule_wrap(function()
            vim.cmd("redrawstatus")
          end),
        },
      }

      local FileEncoding = {
        provider = function()
          local fenc = vim.bo.fenc
          if fenc ~= "" and fenc ~= "utf-8" then
            return "󰧮 " .. fenc:upper() .. " "
          else
            return ""
          end
        end,
        hl = { fg = colors.blue },
      }

      local FileFormat = {
        provider = function()
          local fmt = vim.bo.fileformat
          local os = (vim.fn.has("win32") == 1 and "dos")
            or (vim.fn.has("unix") == 1 and "unix")
            or ""
          if fmt ~= "" and fmt ~= os then
            return "󰧮 " .. fmt:upper() .. " "
          else
            return ""
          end
        end,
        hl = { fg = colors.green },
      }

      local FileNameBlock = {
        init = function(self)
          self.filename = vim.api.nvim_buf_get_name(0)
        end,
      }

      local HelpFileName = {
        condition = function()
          return vim.bo.filetype == "help"
        end,
        provider = function()
          local filename = vim.api.nvim_buf_get_name(0)
          return "󰧮 " .. vim.fn.fnamemodify(filename, ":t")
        end,
        hl = { fg = colors.blue },
      }

      local FileIcon = {
        init = function(self)
          local filename = self.filename
          local extension = vim.fn.fnamemodify(filename, ":e")
          self.icon, self.icon_color =
            require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
        end,
        provider = function(self)
          return self.icon and (self.icon .. " ")
        end,
        hl = function(self)
          return { fg = self.icon_color }
        end,
      }

      local TerminalName = {
        provider = function()
          local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
          return " " .. tname
        end,
        hl = { fg = colors.green, bold = true },
      }

      local FileName = {
        provider = function(self)
          local filename = vim.fn.fnamemodify(self.filename, ":t")
          if filename == "" then
            return "[No Name] "
          end
          return filename .. " "
        end,
        hl = { fg = colors.blue },
      }

      local FileFlags = {
        {
          condition = function()
            return vim.bo.modified
          end,
          provider = "󰷈 ",
          hl = { fg = colors.green },
        },
        {
          condition = function()
            return not vim.bo.modifiable or vim.bo.readonly
          end,
          provider = " ",
          hl = { fg = colors.red },
        },
      }

      FileNameBlock = heirline_util.insert(
        FileNameBlock,
        FileIcon,
        FileName,
        FileFlags,
        { provider = "%<" } -- This means that the statusline is cut here when there's not enough space
      )

      local Ruler = {
        provider = " %7(%l : %1c ",
      }

      local ScrollBar = {

        provider = function()
          return "󰡏 " .. "%P"
        end,
        hl = { fg = colors.purple },
      }

      local LSPActive = {
        condition = conditions.lsp_attached,
        update = { "LspAttach", "LspDetach" },

        on_click = {
          callback = function()
            vim.defer_fn(function()
              vim.cmd("LspInfo")
            end, 100)
          end,
          name = "heirline_LSP",
        },

        provider = function()
          local names = {}
          for _, server in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
            table.insert(names, server.name)
          end
          local lsp_names = table.concat(names, " ")
          return lsp_names ~= "" and " " .. lsp_names .. " " or ""
        end,
        hl = { fg = colors.cyan, bold = true },
      }

      -- local Navic = {
      --   condition = function()
      --     return require("nvim-navic").is_available()
      --   end,
      --   static = {
      --     -- Create a type highlight map
      --     type_hl = {
      --       File = "Directory",
      --       Module = "@include",
      --       Namespace = "@namespace",
      --       Package = "@include",
      --       Class = "@structure",
      --       Method = "@method",
      --       Property = "@property",
      --       Field = "@field",
      --       Constructor = "@constructor",
      --       Enum = "@field",
      --       Interface = "@type",
      --       Function = "@function",
      --       Variable = "@variable",
      --       Constant = "@constant",
      --       String = "@string",
      --       Number = "@number",
      --       Boolean = "@boolean",
      --       Array = "@field",
      --       Object = "@type",
      --       Key = "@keyword",
      --       Null = "@comment",
      --       EnumMember = "@field",
      --       Struct = "@structure",
      --       Event = "@keyword",
      --       Operator = "@operator",
      --       TypeParameter = "@type",
      --     },
      --     -- Bit operation dark magic, see below...
      --     enc = function(line, col, winnr)
      --       return bit.bor(bit.lshift(line, 16), bit.lshift(col, 6), winnr)
      --     end,
      --     -- Line: 16 bit (65535); Col: 10 bit (1023); Winnr: 6 bit (63)
      --     dec = function(c)
      --       local line = bit.rshift(c, 16)
      --       local col = bit.band(bit.rshift(c, 6), 1023)
      --       local winnr = bit.band(c, 63)
      --       return line, col, winnr
      --     end,
      --   },
      --   init = function(self)
      --     local data = require("nvim-navic").get_data() or {}
      --     local children = {}
      --     -- Create a child for each level
      --     for i, d in ipairs(data) do
      --       -- Encode line and column numbers into a single integer
      --       local pos = self.enc(d.scope.start.line, d.scope.start.character, self.winnr)
      --       local child = {
      --         {
      --           provider = d.icon,
      --           hl = self.type_hl[d.type],
      --         },
      --         {
      --           -- Escape `%`s (elixir) and buggy default separators
      --           provider = d.name:gsub("%%", "%%%%"):gsub("%s*->%s*", ""),
      --           -- Highlight icon only or location name as well
      --           hl = self.type_hl[d.type],
      --
      --           on_click = {
      --             -- Pass the encoded position through minwid
      --             minwid = pos,
      --             callback = function(_, minwid)
      --               -- Decode
      --               local line, col, winnr = self.dec(minwid)
      --               vim.api.nvim_win_set_cursor(vim.fn.win_getid(winnr), { line, col })
      --             end,
      --             name = "heirline_navic",
      --           },
      --         },
      --       }
      --       -- Add a separator only if needed
      --       if #data > 1 and i < #data then
      --         table.insert(child, {
      --           provider = "  ",
      --           hl = { fg = colors.fg },
      --         })
      --       end
      --       table.insert(children, child)
      --     end
      --
      --     -- Add a space after the last child
      --     if #data > 1 then
      --       table.insert(children, {
      --         provider = " ",
      --       })
      --     end
      --
      --     -- Instantiate the new child, overwriting the previous one
      --     self.child = self:new(children, 1)
      --   end,
      --
      --   -- Evaluate the children containing navic components
      --   provider = function(self)
      --     return self.child:eval()
      --   end,
      --   --hl = { fg = "gray" },
      --   update = "CursorMoved",
      -- }

      local Diagnostics = {
        on_click = {
          callback = function()
            require("trouble").toggle({ mode = "diagnostics" })
          end,
          name = "heirline_diagnostics",
        },
        condition = conditions.has_diagnostics,

        static = {
          error_icon = require("config").config.icons.diagnostics.Error,
          warn_icon = require("config").config.icons.diagnostics.Warn,
          info_icon = require("config").config.icons.diagnostics.Info,
          hint_icon = require("config").config.icons.diagnostics.Hint,
        },

        init = function(self)
          self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
          self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
          self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
          self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
        end,

        update = { "DiagnosticChanged", "BufEnter" },

        {
          provider = function(self)
            return self.errors > 0 and (self.error_icon .. self.errors .. " ")
          end,
          hl = { fg = colors.red },
        },
        {
          provider = function(self)
            return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
          end,
          hl = { fg = colors.orange },
        },
        {
          provider = function(self)
            return self.info > 0 and (self.info_icon .. self.info .. " ")
          end,
          hl = { fg = colors.blue },
        },
        {
          provider = function(self)
            return self.hints > 0 and (self.hint_icon .. self.hints .. " ")
          end,
          hl = { fg = colors.yellow },
        },
      }

      local Git = {

        on_click = {
          callback = function()
            vim.defer_fn(function()
              vim.cmd("Telescope git_status cwd=" .. vim.fn.expand("%:p:h"))
            end, 100)
          end,
          name = "heirline_git",
        },

        condition = conditions.is_git_repo,
        init = function(self)
          ---@diagnostic disable-next-line: undefined-field
          self.status_dict = vim.b.gitsigns_status_dict
          self.has_changes = self.status_dict.added ~= 0
            or self.status_dict.removed ~= 0
            or self.status_dict.changed ~= 0
        end,

        hl = { fg = colors.orange },

        -- Git branch name
        {
          provider = function(self)
            local branch_name = self.status_dict.head
            return branch_name ~= "" and " " .. branch_name .. " " or ""
          end,
          hl = { bold = true },
        },

        -- You could handle delimiters, icons and counts similar to Diagnostics
        {
          provider = function(self)
            local count = self.status_dict.added or 0
            return count > 0 and (require("config").config.icons.git.added .. count .. " ")
          end,
          hl = { fg = colors.green },
        },
        {
          provider = function(self)
            local count = self.status_dict.removed or 0
            return count > 0 and (require("config").config.icons.git.removed .. count .. " ")
          end,
          hl = { fg = colors.red },
        },
        {
          provider = function(self)
            local count = self.status_dict.changed or 0
            return count > 0 and (require("config").config.icons.git.modified .. count .. " ")
          end,
          hl = { fg = colors.yellow },
        },
      }

      local TablineFileName = {
        provider = function(self)
          local filename = self.filename
          filename = filename == "" and "[No Name]" or vim.fn.fnamemodify(filename, ":t")
          return filename .. " "
        end,
        hl = function(self)
          return { bold = self.is_active or self.is_visible, italic = true }
        end,
      }

      local TablineFileFlags = {
        {
          condition = function(self)
            return vim.api.nvim_buf_get_option(self.bufnr, "modified")
          end,
          provider = "󰷈 ",
          hl = { fg = colors.green },
        },
        {
          condition = function(self)
            return not vim.api.nvim_buf_get_option(self.bufnr, "modifiable")
              or vim.api.nvim_buf_get_option(self.bufnr, "readonly")
          end,
          provider = function(self)
            if vim.api.nvim_buf_get_option(self.bufnr, "buftype") == "terminal" then
              return " "
            else
              return " "
            end
          end,
          hl = function(self)
            if vim.api.nvim_buf_get_option(self.bufnr, "buftype") == "terminal" then
              return { fg = colors.green }
            else
              return { fg = colors.red }
            end
          end,
        },
      }

      local Space = { provider = " " }

      local Align = { provider = "%=" }

      -- Here the filename block finally comes together
      local TablineFileNameBlock = {
        init = function(self)
          self.filename = vim.api.nvim_buf_get_name(self.bufnr)
        end,
        hl = function(self)
          if self.is_active then
            return "TabLineSel"
          elseif not vim.api.nvim_buf_is_loaded(self.bufnr) then
            return { fg = "gray" }
          else
            return "TabLine"
          end
        end,
        on_click = {
          callback = function(_, minwid, _, button)
            if button == "r" then
              require("libs.bufdel").delete_buffer_expr(minwid, false)
            else
              vim.api.nvim_win_set_buf(0, minwid)
            end
          end,
          minwid = function(self)
            return self.bufnr
          end,
          name = "heirline_tabline_buffer_callback",
        },
        Space,
        FileIcon,
        TablineFileName,
        TablineFileFlags,
      }

      local TabLineOffset = {
        condition = function(self)
          local win = vim.api.nvim_tabpage_list_wins(0)[1]
          local bufnr = vim.api.nvim_win_get_buf(win)
          self.winid = win

          if vim.bo[bufnr].filetype == "neo-tree" then
            self.title = " NeoTree"
            return true
          end
        end,

        provider = function(self)
          local title = self.title
          local width = vim.api.nvim_win_get_width(self.winid)
          local pad = math.ceil((width - #title) / 2)
          return string.rep(" ", pad) .. title .. string.rep(" ", pad)
        end,

        hl = function(self)
          if vim.api.nvim_get_current_win() == self.winid then
            return "TablineSel"
          else
            return "Tabline"
          end
        end,
      }

      local BufferLine = heirline_util.make_buflist(
        TablineFileNameBlock,
        { provider = "", hl = { fg = "gray" } },
        { provider = "", hl = { fg = "gray" } }
      )

      local Tabpage = {
        provider = function(self)
          return "%" .. self.tabnr .. "T " .. self.tabpage .. " %T"
        end,
        hl = function(self)
          if not self.is_active then
            return "TabLine"
          else
            return "TabLineSel"
          end
        end,
      }

      local TabPages = {
        -- Only show this component if there's 2 or more tabpages
        condition = function()
          return #vim.api.nvim_list_tabpages() >= 2
        end,
        { provider = "%=" },
        heirline_util.make_tablist(Tabpage),
      }

      local TabLine = { TabLineOffset, BufferLine, TabPages }

      local DefaultStatusline = {
        ViMode,
        FileNameBlock,
        Diagnostics,
        -- Navic,
        Align,
        Git,
        LSPActive,
        Ruler,
        FileEncoding,
        FileFormat,
        ScrollBar,
      }

      local TerminalStatusline = {

        condition = function()
          return conditions.buffer_matches({ buftype = { "terminal" } })
        end,

        -- Quickly add a condition to the ViMode to only show it when buffer is active!
        { condition = conditions.is_active, ViMode },
        TerminalName,
        Align,
      }

      local SpecialStatusline = {
        condition = function()
          return conditions.buffer_matches({
            buftype = { "nofile", "prompt", "help", "quickfix" },
            filetype = { "^git.*", "fugitive" },
          })
        end,

        HelpFileName,
        Align,
      }

      local InactiveStatusline = {
        condition = conditions.is_not_active,
        Align,
      }
      local StatusLines = {

        hl = function()
          if conditions.is_active() then
            return "StatusLine"
          else
            return "StatusLineNC"
          end
        end,

        fallthrough = false,
        SpecialStatusline,
        TerminalStatusline,
        InactiveStatusline,
        DefaultStatusline,
      }

      require("heirline").setup({
        ---@diagnostic disable: missing-fields
        statusline = { StatusLines },
        tabline = { TabLine },
        opts = {
          disable_winbar_cb = function(args)
            return conditions.buffer_matches({
              buftype = { "nofile", "prompt", "help", "quickfix" },
              filetype = { "^git.*", "fugitive", "Trouble", "dashboard" },
            }, args.buf)
          end,
        },
      })

      vim.o.showtabline = 2
      vim.cmd(
        [[au FileType * if index(['wipe', 'delete'], &bufhidden) >= 0 | set nobuflisted | endif]]
      )
    end,
  },

  -- LSP symbol navigation (functions, classes, etc)
  {
    "SmiteshP/nvim-navic",
    lazy = true,
    init = function()
      vim.g.navic_silence = true
      require("libs.utils").on_attach(function(client, buffer)
        if client.server_capabilities.documentSymbolProvider then
          require("nvim-navic").attach(client, buffer)
        end
      end)
    end,
    opts = function()
      return {
        icons = require("config").config.icons.kinds,
      }
    end,
  },
}
