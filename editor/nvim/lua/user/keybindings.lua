-- set the leader to `\`
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- moving windows
vim.keymap.set("n", "gh", ":wincmd h <CR>", { desc = "navigate window left" })
vim.keymap.set("n", "gj", ":wincmd j <CR>", { desc = "navigate window down" })
vim.keymap.set("n", "gk", ":wincmd k <CR>", { desc = "navigate window up" })
vim.keymap.set("n", "gl", ":wincmd l <CR>", { desc = "navigate window right" })

-- closing windows
vim.keymap.set("n", "<leader>q", ":q <CR>", { desc = "quit" })
vim.keymap.set("n", "<leader>Q", ":qa <CR>", { desc = "quit all" })
