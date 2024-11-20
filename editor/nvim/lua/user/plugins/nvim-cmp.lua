return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "onsails/lspkind.nvim",
        { "L3MON4D3/LuaSnip", version = "v2.*" },
    },
    config = function()
        local cmp = require("cmp")
        local lspkind = require("lspkind")

        cmp.setup({
            enabled = true,
            performance = {
                -- debounce = 10,
                -- throttle = 100,
                -- fetching_timeout = 100,
                -- confirm_resolve_timeout = 100,
                -- async_budget = 100,
                -- max_view_entries = 100,
            },
            mapping = cmp.mapping.preset.insert({
                ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                ["<Tab>"] = cmp.mapping.select_next_item(),
                ["<C-k>"] = cmp.mapping.scroll_docs(-4),
                ["<C-j>"] = cmp.mapping.scroll_docs(4),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<CR>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
                ["<C-]>"] = function()
                    if cmp.visible_docs() then
                        cmp.close_docs()
                    else
                        cmp.open_docs()
                    end
                end,
            }),
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end,
            },
            preselect = cmp.PreselectMode.None,
            completion = {
                completeopt = "menuone,noselect",
            },
            formatting = {
                format = lspkind.cmp_format({
                    maxwidth = 30,
                    ellipsis_char = "...",
                }),
            },
            matching = {
                disallow_fuzzy_matching = true,
                disallow_fullfuzzy_matching = true,
                disallow_partial_fuzzy_matching = true,
                disallow_partial_matching = true,
                disallow_prefix_matching = true,
                disallow_symbol_prefix_matching = true,
            },
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "buffer" },
                { name = "path" },
            }),
            view = {
                docs = {
                    auto_open = false,
                },
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            experimental = {
                ghost_text = true,
            },
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "TelescopePrompt",
            callback = function()
                cmp.setup.buffer({ completion = { autocomplete = false } })
            end,
        })
    end,
}
