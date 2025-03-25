-- undo history
vim.o.undofile = true

-- aichat
local tui = {
    buf = nil,
    win = nil,
}
vim.keymap.set("n", "<leader>c", function()
    -- If the window is open, close it
    if tui.win and vim.api.nvim_win_is_valid(tui.win) then
        vim.api.nvim_win_close(tui.win, false)
        tui.win = nil
        return
    end

    -- Reuse buffer if still valid
    if tui.buf and vim.api.nvim_buf_is_valid(tui.buf) then
        -- Find a place to put the window (bottom-left)
        vim.cmd("botright 15split")
        tui.win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(tui.win, tui.buf)
        vim.cmd("startinsert")
        return
    end

    -- Create terminal buffer
    tui.buf = vim.api.nvim_create_buf(false, true)

    -- Open bottom split for it
    vim.cmd("botright 15split")
    tui.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(tui.win, tui.buf)

    -- Launch aichat
    vim.fn.termopen("aichat")

    -- Buffer options
    vim.schedule(function()
        if vim.api.nvim_buf_is_valid(tui.buf) then
            vim.bo[tui.buf].bufhidden = "hide"
            vim.bo[tui.buf].buflisted = false
            vim.bo[tui.buf].filetype = "aichat"
        end
    end)

    vim.cmd("startinsert")
end, { desc = "Open an AI chat in a window split." })

-- formatting
local formatting = require("user.utils.formatting")
formatting.enable_format_on_save()
vim.api.nvim_create_user_command("ToggleFormatOnSave", formatting.toggle_format_on_save, {})

-- LSP inlay hints
vim.api.nvim_create_augroup("user_lsp_config", {})
vim.api.nvim_create_autocmd("LspAttach", {
    group = "user_lsp_config",
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.server_capabilities and client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(false)
        end
    end,
})

-- spacing: we default to 4 spaces unless it is in a specified list
-- (typically simple markup languages)
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
        local filetype = vim.bo.filetype
        for _, ft in ipairs({ "yaml", "markdown", "toml", "json", "proto", "cmake" }) do
            if filetype == ft then
                vim.opt.tabstop = 2
                vim.opt.shiftwidth = 2
                return
            end
        end
        vim.o.tabstop = 4
        vim.o.shiftwidth = 4
    end,
})

-- ui
vim.o.hlsearch = false
vim.wo.number = true
vim.wo.relativenumber = true
vim.t_Co = 256

-- comment continuation
vim.o.formatoptions = "tcro"

-- smartcase search
vim.o.ignorecase = true
vim.o.smartcase = true
