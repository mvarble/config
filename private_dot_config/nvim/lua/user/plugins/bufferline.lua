return {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons", "tinted-theming/tinted-nvim" },
    config = function()
        vim.opt.termguicolors = true
        require("bufferline").setup({
            highlights = {
                fill = {
                    bg = require("bufferline.colors").shade_color(require("tinted-nvim").get_palette().base00, -15),
                },
            },
        })
    end,
}
