return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
        vim.g.mkdp_filetypes = { "markdown" }
        vim.g.mkdp_auto_close = 0
        vim.g.mkdp_preview_options = {
            katex = {
                delimeters = {
                    { left = "$`", right = "`$", display = false },
                    { left = "$$", right = "$$", display = true },
                    { left = "```math", right = "```", display = true },
                },
            },
        }
    end,
    ft = { "markdown" },
}
