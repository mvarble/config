return {
	"b0o/schemastore.nvim",
	{ "stevearc/dressing.nvim", event = "VeryLazy" },
	{ "RRethy/vim-illuminate", event = { "BufReadPre", "BufNewFile" } },
	{
		"machakann/vim-highlightedyank",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.g.highlightedyank_highlight_duration = 100
		end,
	},
}
