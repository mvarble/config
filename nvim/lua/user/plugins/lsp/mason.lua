return {
    {
        "mason-org/mason.nvim",
        version = "^2.2.1",
        dependencies = {
            "mfussenegger/nvim-dap",
            "mfussenegger/nvim-dap-python",
        },
        opts = {
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        },
    },
    {
        "mason-org/mason-lspconfig.nvim",
        version = "^2.1.0",
        dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig", "hrsh7th/cmp-nvim-lsp",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "astro",
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
                    "pyright",
                    "ruff",
                    "sqruff",
                    "stylua",
                    "svelte",
                    "taplo",
                    "ts_ls",
                    "yamlls",
                },
            })
            require("mason-tool-installer").setup({
                ensure_installed = {
                    "clang-format",
                    "jq",
                    "prettierd",
                }
            })
            local capabilities = vim.tbl_deep_extend(
                "force",
                vim.lsp.protocol.make_client_capabilities(),
                require("cmp_nvim_lsp").default_capabilities()
            )
            vim.lsp.config("*", { capabilities = capabilities })
            vim.lsp.config("ruff", {
                capabilities = capabilities,
                on_attach = function(client)
                    client.server_capabilities.hoverProvider = false
                end,
            })
            vim.lsp.config("clangd", {
                capabilities = capabilities,
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "h", "hpp" },
            })
            vim.lsp.config("lua_ls", {
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
    },
}
