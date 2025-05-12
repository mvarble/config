return {
    {
        "mason-org/mason.nvim",
        version = "^1.0.0",
        dependencies = {
            "mfussenegger/nvim-dap",
            "mfussenegger/nvim-dap-python",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
    },
    {
        "mason-org/mason-lspconfig.nvim",
        version = "^1.0.0",
        dependencies = { "mason-org/mason.nvim" },
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
                    "sqlls",
                    "taplo",
                    "ts_ls",
                    "yamlls",
                },
            })

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
                    "sqlls",
                    "stylua",
                    "svelte-language-server",
                    "tree-sitter-cli",
                    "typescript-language-server",
                    "taplo",
                    "yaml-language-server",
                    "yamllint",
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = { "mason-org/mason.nvim", "mason-org/mason-lspconfig.nvim" },
    },
}
