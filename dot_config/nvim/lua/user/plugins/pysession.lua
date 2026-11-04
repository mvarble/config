return {
	{
		dir = vim.fn.stdpath("config") .. "/lua/user/local/pysession.nvim",
		name = "pysession",
		main = "pysession",
		-- `init` runs at startup even though the plugin is lazy-loaded: snapshot the
		-- shell's environment before venv-selector starts rewriting vim.env.
		init = function()
			vim.g.pysession_startup_env = vim.fn.environ()
		end,
		-- Loaded on demand by pysession anyway; listed so Lazy loads it first.
		dependencies = { "linux-cultist/venv-selector.nvim" },
		cmd = "PySession",
		keys = {
			{
				"<leader>c",
				function()
					require("pysession").toggle()
				end,
				desc = "PySession: toggle REPL",
			},
			{
				"<leader>s",
				function()
					require("pysession").send_line()
				end,
				desc = "PySession: send line",
			},
			{
				"<leader>s",
				function()
					require("pysession").send_visual()
				end,
				mode = "x",
				desc = "PySession: send selection",
			},
			{
				"<leader>r",
				function()
					require("pysession").send_cell()
				end,
				desc = "PySession: send cell",
			},
		},
		opts = {
			pixi_frozen = true,
			venv_selector = true,
			venv_dirs = { "~/.venvs", "~/.virtualenvs", "~/.local/share/python" },
		},
	},
}
