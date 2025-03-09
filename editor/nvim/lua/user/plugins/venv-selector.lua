return {
    "linux-cultist/venv-selector.nvim",
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
    opts = {
        stay_on_this_version = true,
    },
    keys = {
        { "<leader>vs", "<cmd>VenvSelect<cr>" },
    },
}
