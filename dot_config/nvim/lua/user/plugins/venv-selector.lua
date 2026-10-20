return {
	"linux-cultist/venv-selector.nvim",
	dependencies = {
		"neovim/nvim-lspconfig",
		{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
	},
	ft = "python",
	lazy = false,
	keys = {
		{ "<leader>vs", "<cmd>VenvSelect<cr>" },
	},
	opts = {
		options = {
			on_venv_activate_callback = function()
				local py = require("venv-selector").python()
				if not py then
					return
				end
				local ok, sniprun = pcall(require, "sniprun")
				if not ok then
					return
				end

				local io = sniprun.config_values.interpreter_options
				io.Python3_fifo = io.Python3_fifo or {}
				if io.Python3_fifo.interpreter ~= py then
					io.Python3_fifo.interpreter = py
					if sniprun.job_id then
						sniprun.reset()
					end -- drop the old REPL
				end
			end,
			statusline_func = {
				nvchad = nil,
				lualine = function()
					local venv_path = require("venv-selector").venv()
					if not venv_path or venv_path == "" then
						return ""
					end
					local venv_name = vim.fn.fnamemodify(venv_path, ":t")
					if venv_name == "" then
						return ""
					elseif venv_name == ".venv" then
						return vim.fn.fnamemodify(venv_path, ":h:t")
					else
						return venv_name
					end
				end,
			},
		},
	},
}
