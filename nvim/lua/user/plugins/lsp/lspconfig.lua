return {
    {
        "mason-org/mason.nvim",
        version = "^2.0.0",
        dependencies = {
            "mfussenegger/nvim-dap",
            "mfussenegger/nvim-dap-python",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
    },
    {
        "mason-org/mason-lspconfig.nvim",
        version = "^2.0.0",
        dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig", "hrsh7th/cmp-nvim-lsp" },
        config = function()
            -- import modules
            local mason = require("mason")
            local mason_lspconfig = require("mason-lspconfig")
            local mason_tool_installer = require("mason-tool-installer")
            local cmp_nvim_lsp = require("cmp_nvim_lsp")

            -- get lsp capabilities of client
            local capabilities = cmp_nvim_lsp.default_capabilities()

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

            -- set up lsp configs of servers installed from mason
            mason_lspconfig.setup({
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
                    "taplo",
                    "ts_ls",
                    "yamlls",
                },
                {
                    function(server_name)
                        vim.lsp.config(server_name, { capabilities = capabilities, enable = true })
                    end,
                    clangd = function()
                        vim.lsp.config("clangd", {
                            capabilities = capabilities,
                            enable = true,
                            filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "h", "hpp" },
                        })
                    end,
                    lua_ls = function()
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
                    ruff = function()
                        vim.lsp.config("ruff", {
                            capabilities = capabilities,
                            on_attach = function(client)
                                if client.name == "ruff" then
                                    client.server_capabilities.hoverProvider = false
                                end
                            end,
                        })
                    end,
                },
            })

            -- automatically install some of the mason tools
            mason_tool_installer.setup({
                ensure_installed = {
                    "astro-language-server",
                    "buf",
                    "clang-format",
                    "clangd",
                    "cmake-language-server",
                    "dockerls",
                    "gitlab-ci-ls",
                    "jq",
                    "json-lsp",
                    "julia-lsp",
                    "lua-language-server",
                    "prettierd",
                    "pyright",
                    "ruff",
                    "stylua",
                    "svelte-language-server",
                    "tree-sitter-cli",
                    "typescript-language-server",
                    "taplo",
                    "yaml-language-server",
                    "yamllint",
                },
            })

            -- set symbols for diagnostics
            local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
            for type, icon in pairs(signs) do
                local hl = "DiagnosticSign" .. type
                vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
            end
        end,
    },
}
