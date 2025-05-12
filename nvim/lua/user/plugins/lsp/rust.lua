return {
    {
        "saecki/crates.nvim",
        version = "v0.3.0",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("crates").setup({
                null_ls = {
                    enabled = true,
                    name = "crates.nvim",
                },
                popup = {
                    border = "rounded",
                },
            })
        end,
    },
    { "mrcjkb/rustaceanvim", version = "^5" },
}
