return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons", "RRethy/base16-nvim" },
	config = function()
		vim.opt.termguicolors = true
		local base_bg = require("base16-colorscheme").colors.base00
		require("bufferline").setup({
			highlights = {
				fill = {
					bg = require("bufferline.colors").shade_color(base_bg, -25),
				},
			},
		})
	end,
}
