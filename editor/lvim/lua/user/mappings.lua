-- change the leader to backslash
lvim.leader = '\\'

-- quick command
lvim.keys.normal_mode[";"] = ":"

-- change diagnostics
lvim.lsp.buffer_mappings.normal_mode["gn"] = lvim.lsp.buffer_mappings.normal_mode["gl"]
lvim.lsp.buffer_mappings.normal_mode["gngn"] = lvim.lsp.buffer_mappings.normal_mode["glgl"]
lvim.lsp.buffer_mappings.normal_mode["gl"] = nil
lvim.lsp.buffer_mappings.normal_mode["glgl"] = nil

-- remove alt stuff
lvim.keys.insert_mode["<A-j>"] = false
lvim.keys.insert_mode["<A-k>"] = false
lvim.keys.normal_mode["<A-j>"] = false
lvim.keys.normal_mode["<A-k>"] = false
lvim.keys.visual_block_mode["<A-j>"] = false
lvim.keys.visual_block_mode["<A-k>"] = false
lvim.keys.visual_block_mode["J"] = false
lvim.keys.visual_block_mode["K"] = false

-- moving windows
lvim.keys.normal_mode["gh"] = ":wincmd h <CR>"
lvim.keys.normal_mode["gj"] = ":wincmd j <CR>"
lvim.keys.normal_mode["gk"] = ":wincmd k <CR>"
lvim.keys.normal_mode["gl"] = ":wincmd l <CR>"

-- buffer control
lvim.keys.normal_mode["<C-d>"] = ":BufferKill<CR>"
lvim.keys.normal_mode["<S-H>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<S-L>"] = ":BufferLineCycleNext<CR>"
