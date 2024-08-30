vim.api.nvim_create_augroup("user_lsp_config", {})
vim.api.nvim_create_autocmd("LspAttach", {
	group = "user_lsp_config",
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.server_capabilities and client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true)
		end
	end,
})
