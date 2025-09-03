return {
    "tinted-theming/tinted-nvim",
    priority = 1000,
    config = function()
        vim.opt.termguicolors = true
        require("tinted-colorscheme").setup()
    end,
}
