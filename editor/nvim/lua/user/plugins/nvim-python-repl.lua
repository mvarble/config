return {
    "geg2102/nvim-python-repl",
    dependencies = "nvim-treesitter",
    ft = { "python" },
    config = function()
        local repl = require("nvim-python-repl")
        repl.setup({ vsplit = false })
        vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { silent = true })
        vim.keymap.set("n", "gr", repl.open_repl, { desc = "Opens a Python REPL in a window split" })
        vim.keymap.set("v", "<leader>t", repl.send_visual_to_repl, { desc = "Sends selection to REPL" })
        vim.keymap.set("n", "<leader>t", repl.send_statement_definition, { desc = "Sends statement to REPL" })
    end,
}
