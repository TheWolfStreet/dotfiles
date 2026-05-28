-- Reload QML buffers changed externally so qmlls picks up the new content.
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
    pattern = "*.qml",
    callback = function()
        vim.cmd("silent! checktime")
    end,
})

local qmlls_bin = vim.fn.exepath("qmlls")
local qt_qml = qmlls_bin ~= "" and (vim.fn.fnamemodify(qmlls_bin, ":h:h") .. "/lib/qt-6/qml") or ""

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "qml", "qmljs" },
    callback = function(ev)
        local root = vim.fs.root(ev.buf, { ".qmlls.ini", "CMakeLists.txt", ".git" })
        if not root then return end

        local cmd = { qmlls_bin ~= "" and qmlls_bin or "qmlls" }
        local build = root .. "/build"
        if vim.uv.fs_stat(build) then
            vim.list_extend(cmd, { "-b", build, "-I", build })
        end
        if qt_qml ~= "" and vim.uv.fs_stat(qt_qml) then
            vim.list_extend(cmd, { "-I", qt_qml })
        end

        vim.lsp.start({ name = "qmlls", cmd = cmd, root_dir = root }, {
            bufnr = ev.buf,
            reuse_client = function(client, config) return client.name == config.name end,
        })
    end,
})

return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = { "qmljs" },
        },
    },
    {
        "stevearc/conform.nvim",
        optional = true,
        opts = {
            formatters_by_ft = {
                qml = { "qmlformat" },
            },
        },
    },
}
