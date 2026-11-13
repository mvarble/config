local M = {}

function M.clear_augroup(name)
    -- defer the function in case the autocommand is still in-use
    vim.schedule(function()
        pcall(function()
            vim.api.nvim_clear_autocmds({ group = name })
        end)
    end)
end

function M.format_filter(client)
    if client:supports_method("textDocument/formatting") then
        return true
    else
        return false
    end
end

-- `textDocument/formatting` never sorts imports (ruff keeps that in the linter), so ask the
-- servers listed here for their organize-imports code action, synchronously, before formatting.
M.organize_imports_kinds = {
    ruff = "source.organizeImports.ruff",
}

function M.organize_imports(bufnr, timeout_ms)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    timeout_ms = timeout_ms or 1000
    for name, kind in pairs(M.organize_imports_kinds) do
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = name })) do
            local params = {
                textDocument = vim.lsp.util.make_text_document_params(bufnr),
                range = {
                    start = { line = 0, character = 0 },
                    ["end"] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 },
                },
                context = { only = { kind }, diagnostics = {} },
            }
            local res = client:request_sync("textDocument/codeAction", params, timeout_ms, bufnr)
            for _, action in ipairs(res and res.result or {}) do
                if not action.edit and client:supports_method("codeAction/resolve") then
                    local resolved = client:request_sync("codeAction/resolve", action, timeout_ms, bufnr)
                    action = resolved and resolved.result or action
                end
                if action.edit then
                    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
                end
            end
        end
    end
end

function M.format(opts)
    opts = opts or {}
    opts.filter = opts.filter or M.format_filter
    M.organize_imports(opts.bufnr, opts.timeout_ms)
    return vim.lsp.buf.format(opts)
end

function M.get_format_on_save_opts()
    return {
        enabled = false,
        pattern = "*",
        timeout = 1000,
        filter = M.format_filter,
    }
end

function M.enable_format_on_save()
    local opts = M.get_format_on_save_opts()
    vim.api.nvim_create_augroup("lsp_format_on_save", {})
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = "lsp_format_on_save",
        pattern = opts.pattern,
        callback = function()
            M.format({ timeout_ms = opts.timeout, filter = opts.filter })
        end,
    })
end

function M.disable_format_on_save()
    M.clear_augroup("lsp_format_on_save")
end

function M.toggle_format_on_save()
    local exists, autocmds = pcall(vim.api.nvim_get_autocmds, {
        group = "lsp_format_on_save",
        event = "BufWritePre",
    })
    if not exists or #autocmds == 0 then
        M.enable_format_on_save()
    else
        M.disable_format_on_save()
    end
end

return M
