return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			ensure_installed = {
				"astro",
				-- not yet in the mason-lspconfig package
				-- "bacon_ls",
				"clangd",
				"cmake",
				"cssls",
				"cssmodules_ls",
				"dockerls",
				"eslint",
				"gitlab_ci_ls",
				"html",
				"jsonls",
				"julials",
				"lua_ls",
				"ruff_lsp",
				"sqlls",
				"taplo",
				"ts_ls",
				-- TODO: see about installing this.
				-- "tabby_ml",
				"yamlls",
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"astro-language-server",
				"bacon-ls",
				"buf",
				"clang-format",
				"clangd",
				"cmakelint",
				"cmakelang",
				"dockerls",
				"eslint_d",
				"gitlab-ci-ls",
				"jq",
				"json-lsp",
				"julia-lsp",
				"lua-language-server",
				"prettierd",
				"ruff-lsp",
				"sqlls",
				"stylua",
				"svelte-language-server",
				"typescript-language-server",
				"taplo",
				"yaml-language-server",
				"yamllint",
			},
		})
	end,
}
