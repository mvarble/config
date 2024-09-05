local M = {}

function M.clear_augroup(name)
	-- defer the function in case the autocommand is still in-use
	vim.schedule(function()
		pcall(function()
			vim.api.nvim_clear_autocmds({ group = name })
		end)
	end)
end

function M.format_filter(client)
	local filetype = vim.bo.filetype
	local n = require("null-ls")
	local s = require("null-ls.sources")
	local method = n.methods.FORMATTING
	local available_formatters = s.get_available(filetype, method)

	if #available_formatters > 0 then
		return client.name == "null-ls"
	elseif client.supports_method("textDocument/formatting") then
		return true
	else
		return false
	end
end

function M.format(opts)
	opts = opts or {}
	opts.filter = opts.filter or M.format_filter
	return vim.lsp.buf.format(opts)
end

function M.get_format_on_save_opts()
	return {
		enabled = false,
		pattern = "*",
		timeout = 1000,
		filter = M.format_filter,
	}
end

function M.enable_format_on_save()
	local opts = M.get_format_on_save_opts()
	vim.api.nvim_create_augroup("lsp_format_on_save", {})
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = "lsp_format_on_save",
		pattern = opts.pattern,
		callback = function()
			M.format({ timeout_ms = opts.timeout, filter = opts.filter })
		end,
	})
end

function M.disable_format_on_save()
	M.clear_augroup("lsp_format_on_save")
end

function M.toggle_format_on_save()
	local exists, autocmds = pcall(vim.api.nvim_get_autocmds, {
		group = "lsp_format_on_save",
		event = "BufWritePre",
	})
	if not exists or #autocmds == 0 then
		M.enable_format_on_save()
	else
		M.disable_format_on_save()
	end
end

return M
