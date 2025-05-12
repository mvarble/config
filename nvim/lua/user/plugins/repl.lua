return {
    "Vigemus/iron.nvim",
    event = "VimEnter",
    config = function()
        local iron = require("iron.core")
        local common = require("iron.fts.common")
        iron.setup({
            config = {
                scratch_repl = false,
                repl_definition = {
                    sh = {
                        command = { "bash" },
                    },
                    fish = {
                        command = { "fish" },
                    },
                    python = {
                        command = { "ipython", "--no-autoindent" },
                        format = common.bracketed_paste_python,
                        block_dividers = { "# %%", "#%%", "##" },
                    },
                    matlab = {
                        command = { "octave" },
                        block_dividers = { "%%" },
                    },
                },
                repl_filetype = function(_, ft)
                    return ft
                end,
                repl_open_cmd = "belowright 20split",
            },
            keymaps = {
                toggle_repl = "<leader>rr",
                restart_repl = "<leader>rq",
                visual_send = "<leader>sv",
                send_file = "<leader>sf",
                send_line = "<leader>sl",
                send_code_block = "<leader>sb",
                cr = "<leader>s<cr>",
                interrupt = "<leader>s<leader>",
                exit = "<leader>sq",
                clear = "<leader>sc",
            },
            -- If the highlight is on, you can change how it looks
            -- For the available options, check nvim_set_hl
            highlight = {
                italic = true,
            },
            ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
        })

        -- iron also has a list of commands, see :h iron-commands for all available commands
        vim.keymap.set("n", "<leader>rf", "<cmd>IronFocus<cr>")
        vim.keymap.set("n", "<leader>rh", "<cmd>IronHide<cr>")
    end,
}
