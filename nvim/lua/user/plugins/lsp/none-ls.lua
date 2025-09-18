return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvimtools/none-ls-extras.nvim",
    },
    config = function()
        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                -- diagnostics
                null_ls.builtins.diagnostics.buf,
                null_ls.builtins.diagnostics.fish,
                require("none-ls.diagnostics.ruff"),
                null_ls.builtins.diagnostics.yamllint,

                -- formatting
                null_ls.builtins.formatting.buf,
                null_ls.builtins.formatting.clang_format.with({
                    filetypes = { "c", "cpp", "h", "hpp", "cuda" },
                }),
                null_ls.builtins.formatting.d2_fmt,
                null_ls.builtins.formatting.fish_indent,
                require("none-ls.formatting.jq"),
                null_ls.builtins.formatting.prettierd,
                require("none-ls.formatting.ruff"),
                require("none-ls.formatting.ruff_format"),
                require("none-ls.formatting.rustfmt").with({
                    extra_args = { "--edition", "2018" },
                }),
                null_ls.builtins.formatting.stylua,
                require("none-ls.formatting.trim_newlines"),
                require("none-ls.formatting.trim_whitespace"),
            },
        })
    end,
}
