return {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
    },
    config = function()
        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                -- code actions
                require("none-ls.code_actions.eslint_d"),

                -- diagnostics
                null_ls.builtins.diagnostics.actionlint,
                null_ls.builtins.diagnostics.buf,
                null_ls.builtins.diagnostics.cmake_lint,
                null_ls.builtins.diagnostics.codespell,
                require("none-ls.diagnostics.eslint_d"),
                null_ls.builtins.diagnostics.fish,
                null_ls.builtins.diagnostics.markdownlint_cli2,
                null_ls.builtins.diagnostics.tidy,
                null_ls.builtins.diagnostics.yamllint,

                -- formatting
                null_ls.builtins.formatting.buf,
                null_ls.builtins.formatting.clang_format.with({
                    filetypes = { "c", "cpp", "h", "hpp", "cuda" }
                }),
                null_ls.builtins.formatting.cmake_format,
                null_ls.builtins.formatting.d2_fmt,
                require("none-ls.formatting.eslint_d"),
                null_ls.builtins.formatting.fish_indent,
                require("none-ls.formatting.jq"),
                null_ls.builtins.formatting.mdformat,
                null_ls.builtins.formatting.prettierd,
                require("none-ls.formatting.rustfmt"),
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.formatting.tidy,
                require("none-ls.formatting.trim_newlines"),
                require("none-ls.formatting.trim_whitespace"),
                require("none-ls.formatting.yq"),
            }
        })
    end
}
