return {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
        "neovim/nvim-lspconfig",
        { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
        "mfussenegger/nvim-dap",
        "mfussenegger/nvim-dap-python",
    },
    lazy = false,
    branch = "regexp",
    keys = {
        { "<leader>vs", "<cmd>VenvSelect<cr>" },
    },
    config = function()
        require("venv-selector").setup({})
    end,
}
