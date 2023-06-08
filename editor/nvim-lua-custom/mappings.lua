---@type MappingsTable
local M = {}

-- general mappings
M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["gh"] = { ":wincmd h <CR>", "goto left pane", opts = { nowait = true }},
    ["gj"] = { ":wincmd j <CR>", "goto lower pane", opts = { nowait = true }},
    ["gk"] = { ":wincmd k <CR>", "goto upper pane", opts = { nowait = true }},
    ["gl"] = { ":wincmd l <CR>", "goto right pane", opts = { nowait = true }},
  },
  v = {
    ["<leader>l"] = {
      ":<C-u>call unicoder#selection()<CR>",
      "turn latex code to unicode",
      { noremap = true },
    },
  },
}

-- nvim-tree mappings
M.nvimtree = {
  n = {
    ["<C-f>"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvim-tree" },
  },
}

-- tabufline
M.tabufline = {
  n = {
    ["<S-L>"] = {
      function()
        require("nvchad_ui.tabufline").tabuflineNext()
      end,
      "Goto next buffer",
    },
    ["<S-H>"] = {
      function()
        require("nvchad_ui.tabufline").tabuflinePrev()
      end,
      "Goto previous buffer",
    },
    ["<C-d>"] = {
      function()
        require("nvchad_ui.tabufline").close_buffer()
      end,
      "Close buffer",
    },
  }
}

return M
