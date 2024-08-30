-- set the leader to `\`
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- window navigation
vim.keymap.set("n", "gh", ":wincmd h <CR>", { desc = "navigate window left" })
vim.keymap.set("n", "gj", ":wincmd j <CR>", { desc = "navigate window down" })
vim.keymap.set("n", "gk", ":wincmd k <CR>", { desc = "navigate window up" })
vim.keymap.set("n", "gl", ":wincmd l <CR>", { desc = "navigate window right" })

-- buffer navigation
vim.keymap.set("n", "H", ":bp <CR>", { desc = "previous buffer" })
vim.keymap.set("n", "L", ":bn <CR>", { desc = "next buffer" })
vim.keymap.set("n", "<C-d>", ":bp<bar>sp<bar>bn<bar>bd<CR> <CR>", { desc = "close buffer" })

-- closing windows
vim.keymap.set("n", "<leader>q", ":q <CR>", { desc = "quit" })
vim.keymap.set("n", "<leader>Q", ":qa <CR>", { desc = "quit all" })
