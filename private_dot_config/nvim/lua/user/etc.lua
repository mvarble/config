-- undo history
vim.o.undofile = true

-- formatting
local formatting = require("user.utils.formatting")
formatting.enable_format_on_save()
vim.api.nvim_create_user_command("ToggleFormatOnSave", formatting.toggle_format_on_save, {})

-- create new-line with current time in format `[HH:MM]`
vim.keymap.set("n", "<leader>nt", function()
    local time = tostring(os.date("[%H:%M]"))
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, false, { time })
end, { desc = "Insert blank line and current time [HH:MM]" })

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

-- configure LSP diagnostic sign icons
vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰠠 ",
            [vim.diagnostic.severity.INFO] = " ",
        },
    },
})

-- Quiet LSP ServerCancelled error
for _, method in ipairs({ "textDocument/diagnostic", "workspace/diagnostic" }) do
    local default_diagnostic_handler = vim.lsp.handlers[method]
    vim.lsp.handlers[method] = function(err, result, context, config)
        if err ~= nil and err.code == -32802 then
            return
        end
        return default_diagnostic_handler(err, result, context, config)
    end
end

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
