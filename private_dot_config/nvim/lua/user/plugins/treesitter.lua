local languages = {
    "astro",
    "bash",
    "c",
    "cpp",
    "css",
    "dockerfile",
    "fish",
    "gitignore",
    "html",
    "javascript",
    "json",
    "latex",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
    "rust",
    "svelte",
    "toml",
    "typescript",
    "yaml",
}

return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    dependencies = { "windwp/nvim-ts-autotag", "tinted-theming/tinted-nvim" },
    config = function()
        require("nvim-treesitter").install(languages)

        vim.treesitter.language.register("rust", "rs")
        vim.treesitter.language.register("javascript", { "js", "mjs", "cjs" })
        vim.treesitter.language.register("typescript", { "ts", "mts", "cts" })
        vim.treesitter.language.register("python", "py")
        vim.treesitter.language.register("yaml", "yml")
        vim.treesitter.language.register("bash", "sh")
        vim.treesitter.language.register("markdown", "md")

        -- Treat $$ as latex in Markdown
        vim.api.nvim_set_hl(0, "@latex", { link = "Special" })
        vim.api.nvim_create_autocmd("BufRead", {
            pattern = { "*.md", "*.svx" },
            callback = function()
                vim.cmd([[
                    syntax region texMath start=/\v^\$\$/ end=/\v\$\$$/ contains=texZone
                    highlight link texMath Special
                ]])
            end,
        })

        -- add colors to headers in Markdown
        local colorscheme = require("tinted-nvim").get_palette()
        local orange = colorscheme.base09
        local yellow = colorscheme.base0A
        vim.api.nvim_set_hl(0, "@header.h1", { fg = orange, bold = true })
        vim.api.nvim_set_hl(0, "@header.h2", { fg = orange, bold = true })
        vim.api.nvim_set_hl(0, "@header.h3", { fg = orange, bold = true })
        vim.api.nvim_set_hl(0, "@header.h4", { fg = orange, bold = true })
        vim.api.nvim_set_hl(0, "@header.h5", { fg = orange, bold = true })
        vim.api.nvim_set_hl(0, "@header.h6", { fg = orange, bold = true })

        -- add colors to line-items in Markdown
        vim.api.nvim_set_hl(0, "@list", { fg = yellow, bold = true })
    end,
}
