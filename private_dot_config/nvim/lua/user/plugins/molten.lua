return {
	"benlubas/molten-nvim",
	version = "^1.0.0",
	init = function()
		local bind = function(mode, shortcut, cmd, desc)
			vim.keymap.set(mode, shortcut, cmd, { silent = true, desc = desc })
		end
		bind("n", "<leader>mi", ":MoltenInit<CR>", "Initilize Molten Plugin")
		bind("n", "<leader>ki", ":JupyterAttach<CR>", "Attach Jupyter Kernel for nvim-cmp")
		bind("n", "<leader>t", ":MoltenEvaluateOperator<CR>", "Run operator selection")
		bind("n", "<leader>rr", ":MoltenReevaluateCell<CR>", "Reevaluate cell")
		bind("n", "<leader>mo", ":MoltenImagePopup<CR>", "Open image")
		bind("v", "<leader>r", ":<C-u>MoltenEvaluateVisual<CR>gv", "Evaluate visual")
	end,
}
