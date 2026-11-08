-- Parser names (not filetypes). Filetypes are derived from these below.
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

-- Markdown highlight overrides. Re-applied on every :colorscheme, since
-- loading a colorscheme clears custom highlight groups.
local function set_markdown_highlights()
    local palette = require("catppuccin.palettes").get_palette("latte")
    local heading = { fg = palette.peach, bold = true }

    for level = 1, 6 do
        vim.api.nvim_set_hl(0, ("@markup.heading.%d.markdown"):format(level), heading)
    end
    vim.api.nvim_set_hl(0, "@markup.list.markdown", { fg = palette.yellow, bold = true })

    -- $$ ... $$ blocks (markdown_inline captures them as @markup.math and
    -- injects the latex parser for the contents).
    vim.api.nvim_set_hl(0, "@markup.math.markdown_inline", { link = "Special" })
end

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- the rewrite; `master` is frozen and has a different API
    lazy = false, -- main does not support lazy-loading
    build = ":TSUpdate",
    dependencies = { "windwp/nvim-ts-autotag", "catppuccin/nvim" },
    config = function()
        -- Async; already-installed parsers are skipped.
        require("nvim-treesitter").install(languages)

        -- mdsvex files: treat as markdown (Neovim doesn't detect .svx).
        vim.filetype.add({ extension = { svx = "markdown" } })

        -- main does not enable highlighting itself; start it per buffer.
        local filetypes = {}
        for _, lang in ipairs(languages) do
            vim.list_extend(filetypes, vim.treesitter.language.get_filetypes(lang))
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
            pattern = filetypes,
            callback = function(args)
                -- pcall: the parser may still be installing on first launch.
                pcall(vim.treesitter.start, args.buf)
            end,
        })

        set_markdown_highlights()
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("treesitter_markdown_hl", { clear = true }),
            callback = set_markdown_highlights,
        })

        require("nvim-ts-autotag").setup()
    end,
}
