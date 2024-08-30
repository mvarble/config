return {
    "folke/which-key.nvim",
    dependencies = { "echasnovski/mini.icons" },
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 750
    end,
    opts = {}
}
