-- https://gist.github.com/Lamarcke/36e086dd3bb2cebc593d505e2f838e07
local function get_attached_clients()
	local buf_clients = vim.lsp.get_active_clients({ bufnr = 0 })
	if #buf_clients == 0 then
		return "LSP Inactive"
	end

	local buf_ft = vim.bo.filetype
	local buf_client_names = {}

	-- add client
	for _, client in pairs(buf_clients) do
		if client.name ~= "copilot" and client.name ~= "null-ls" then
			table.insert(buf_client_names, client.name)
		end
	end

	-- Generally, you should use either null-ls or nvim-lint + formatter.nvim, not both.

	-- Add sources (from null-ls)
	-- null-ls registers each source as a separate attached client, so we need to filter for unique names down below.
	local null_ls_s, null_ls = pcall(require, "null-ls")
	if null_ls_s then
		local sources = null_ls.get_sources()
		for _, source in ipairs(sources) do
			if source._validated then
				for ft_name, ft_active in pairs(source.filetypes) do
					if ft_name == buf_ft and ft_active then
						table.insert(buf_client_names, source.name)
					end
				end
			end
		end
	end

	-- Add linters (from nvim-lint)
	local lint_s, lint = pcall(require, "lint")
	if lint_s then
		for ft_k, ft_v in pairs(lint.linters_by_ft) do
			if type(ft_v) == "table" then
				for _, linter in ipairs(ft_v) do
					if buf_ft == ft_k then
						table.insert(buf_client_names, linter)
					end
				end
			elseif type(ft_v) == "string" then
				if buf_ft == ft_k then
					table.insert(buf_client_names, ft_v)
				end
			end
		end
	end

	-- Add formatters (from formatter.nvim)
	local formatter_s, _ = pcall(require, "formatter")
	if formatter_s then
		local formatter_util = require("formatter.util")
		for _, formatter in ipairs(formatter_util.get_available_formatters_for_ft(buf_ft)) do
			if formatter then
				table.insert(buf_client_names, formatter)
			end
		end
	end

	-- This needs to be a string only table so we can use concat below
	local unique_client_names = {}
	for _, client_name_target in ipairs(buf_client_names) do
		local is_duplicate = false
		for _, client_name_compare in ipairs(unique_client_names) do
			if client_name_target == client_name_compare then
				is_duplicate = true
			end
		end
		if not is_duplicate then
			table.insert(unique_client_names, client_name_target)
		end
	end

	local client_names_str = table.concat(unique_client_names, ", ")
	local language_servers = string.format("[%s]", client_names_str)

	return language_servers
end

return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"RRethy/base16-nvim",
	},
	config = function()
		local lualine = require("lualine")
		local colorscheme = require("base16-colorscheme").colors

		local colors = {
			normal = colorscheme.base0C,
			insert = colorscheme.base0B,
			violet = colorscheme.base03,
			command = colorscheme.base0A,
			replace = colorscheme.base09,
			fg = colorscheme.base05,
			bg = colorscheme.base02,
			inactive_fg = colorscheme.base04,
			inactive_bg = colorscheme.base01,
		}

		local attached_clients = {
			get_attached_clients,
			color = {
				gui = "bold",
			},
		}

		-- configure lualine with modified theme
		lualine.setup({
			options = {
				theme = {
					normal = {
						a = { bg = colors.normal, fg = colors.bg, gui = "bold" },
						b = { bg = colors.bg, fg = colors.fg },
						c = { bg = colors.bg, fg = colors.fg },
					},
					insert = {
						a = { bg = colors.insert, fg = colors.bg, gui = "bold" },
						b = { bg = colors.bg, fg = colors.fg },
						c = { bg = colors.bg, fg = colors.fg },
					},
					visual = {
						a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
						b = { bg = colors.bg, fg = colors.fg },
						c = { bg = colors.bg, fg = colors.fg },
					},
					command = {
						a = { bg = colors.command, fg = colors.bg, gui = "bold" },
						b = { bg = colors.bg, fg = colors.fg },
						c = { bg = colors.bg, fg = colors.fg },
					},
					replace = {
						a = { bg = colors.replace, fg = colors.bg, gui = "bold" },
						b = { bg = colors.bg, fg = colors.fg },
						c = { bg = colors.bg, fg = colors.fg },
					},
					inactive = {
						a = { bg = colors.inactive_bg, fg = colors.inactive_fg, gui = "bold" },
						b = { bg = colors.inactive_bg, fg = colors.inactive_fg },
						c = { bg = colors.inactive_bg, fg = colors.inactive_fg },
					},
				},
			},
			sections = {
				lualine_x = {
					attached_clients,
					{ "filetype" },
				},
			},
			extensions = { "mason" },
		})
	end,
}
