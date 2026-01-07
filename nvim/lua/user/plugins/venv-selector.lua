return {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
        "neovim/nvim-lspconfig",
        { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    ft = "python",
    lazy = false,
    keys = {
        { "<leader>vs", "<cmd>VenvSelect<cr>" },
    },
    opts = {},
}
