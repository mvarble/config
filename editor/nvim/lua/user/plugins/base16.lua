return {
	"RRethy/base16-nvim",
	priority = 1000,
	config = function()
		vim.opt.termguicolors = true
		require("base16-colorscheme").with_config({
			telescope = true,
			indentblankline = true,
			notify = true,
			ts_rainbow = true,
			cmp = true,
			illuminate = true,
			dapui = true,
		})
		vim.cmd([[colorscheme base16-tomorrow-night-eighties]])
	end,
}
