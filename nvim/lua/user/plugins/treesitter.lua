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
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = { "windwp/nvim-ts-autotag", "tinted-theming/tinted-nvim" },
    config = function()
        local treesitter = require("nvim-treesitter.configs")
        treesitter.setup({
            highlight = {
                enable = true,
                disable = function(_, bufnr)
                    local buf_name = vim.api.nvim_buf_get_name(bufnr)
                    local file_size = vim.api.nvim_call_function("getfsize", { buf_name })
                    return file_size > 256 * 1024
                end,
            },
            indent = { enable = true, additional_vim_regex_highlighting = false },
            autotag = {
                enable = true,
            },
            ensure_installed = languages,
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-space>",
                    node_incremental = "<C-space>",
                    scope_incremental = false,
                    node_decremental = "<bs>",
                },
            },
        })

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
        local colorscheme = require("tinted-colorscheme").colors
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
