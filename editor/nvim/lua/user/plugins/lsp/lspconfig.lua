return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
        local lspconfig = require("lspconfig")
        local mason_lspconfig = require("mason-lspconfig")
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        local capabilities = cmp_nvim_lsp.default_capabilities()

        mason_lspconfig.setup_handlers({
            -- default handler for installed servers
            function(server_name)
                lspconfig[server_name].setup({ capabilities = capabilities, enable = true })
            end,
            clangd = function()
                lspconfig.clangd.setup({
                    capabilities = capabilities,
                    enable = true,
                    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "h", "hpp" },
                })
            end,
            lua_ls = function()
                lspconfig.lua_ls.setup({
                    capabilities = capabilities,
                    on_init = function(client)
                        client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
                            runtime = {
                                version = "LuaJIT",
                            },
                            workspace = {
                                checkThirdParty = false,
                                library = {
                                    vim.env.VIMRUNTIME,
                                },
                            },
                        })
                    end,
                    settings = {
                        Lua = {},
                    },
                })
            end,
            ruff_lsp = function()
                lspconfig.ruff_lsp.setup({
                    capabilities = capabilities,
                    on_attach = function(client)
                        if client.name == "ruff_lsp" then
                            client.server_capabilities.hoverProvider = false
                        end
                    end,
                })
            end,
        })

        local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end
    end,
}
