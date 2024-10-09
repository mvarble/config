return {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons", "RRethy/base16-nvim" },
    config = function()
        vim.opt.termguicolors = true
        require("bufferline").setup({
            highlights = {
                fill = {
                    bg = require("bufferline.colors").shade_color(require("base16-colorscheme").colors.base00, -15),
                },
            },
        })
    end,
}
