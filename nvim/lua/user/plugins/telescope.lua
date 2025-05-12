return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-tree/nvim-web-devicons",
        "folke/todo-comments.nvim",
        "ahmedkhalf/project.nvim",
    },
    config = function()
        local telescope = require("telescope")

        require("project_nvim").setup({
            detection_methods = { "pattern" },
            patterns = { ".git" },
        })

        telescope.setup({
            defaults = {
                layout_strategy = "vertical",
                layout_config = {
                    vertical = {
                        width = 0.5,
                        height = 0.5,
                    },
                },
                path_display = { "smart" },
            },
        })

        telescope.load_extension("fzf")
        telescope.load_extension("projects")

        vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
        vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
        vim.keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
        vim.keymap.set(
            "n",
            "<leader>fc",
            "<cmd>Telescope grep_string<cr>",
            { desc = "Find string under cursor in cwd" }
        )
        vim.keymap.set("n", "<leader>fp", "<cmd>Telescope projects<cr>", { desc = "Find projects" })
        vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
    end,
}
