return {
    "tinted-theming/tinted-nvim",
    priority = 1000,
    config = function()
        vim.opt.termguicolors = true
        require("tinted-nvim").setup({
            selector = { enabled = true, cmd = "tinty current" },
        })
    end,
}
