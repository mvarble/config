return {
	"michaelb/sniprun",
	build = "sh install.sh",
	config = function()
		require("sniprun").setup({
			selected_interpreters = { "Python3_fifo" },
			repl_enable = { "Python3_fifo" },
		})
		vim.keymap.set("n", "<leader>r", "<cmd>SnipRun<cr>", { desc = "Run current line." })
		vim.keymap.set("v", "<leader>r", ":SnipRun<cr>", { desc = "Run visual selection." })
	end,
}
