return {
    "joom/latex-unicoder.vim",
    config = function()
        vim.g.unicoder_cancel_normal = true
        vim.g.unicoder_cancel_insert = true
        vim.g.unicoder_cancel_visual = true
        vim.keymap.set(
            "v",
            "<leader>l",
            ":call unicoder#selection()<CR>",
            { desc = "Convert LaTeX inputs to unicode." }
        )
    end,
}
