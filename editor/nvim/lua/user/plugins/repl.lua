return {
    "pappasam/nvim-repl",
    event = "VimEnter",
    init = function()
        vim.g["repl_filetype_commands"] = {
            javascript = "node",
            python = "ipython --no-autoindent",
        }
        vim.g["repl_split"] = "top"
    end,
    keys = {
        { "<Leader>cc", "<Cmd>ReplNewCell<CR>",   mode = "n", desc = "Create New Cell" },
        { "<Leader>cr", "<Plug>(ReplSendCell)",   mode = "n", desc = "Send Repl Cell" },
        { "<Leader>r",  "<Plug>(ReplSendLine)",   mode = "n", desc = "Send Repl Line" },
        { "<Leader>r",  "<Plug>(ReplSendVisual)", mode = "x", desc = "Send Repl Visual Selection" },
    },
}
