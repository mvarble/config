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
    dependencies = { "windwp/nvim-ts-autotag" },
    config = function()
        local treesitter = require("nvim-treesitter.configs")
        treesitter.setup({
            highlight = {
                enable = true,
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
    end,
}
