return {
    "Vigemus/iron.nvim",
    event = "VimEnter",
    config = function()
        local iron = require("iron.core")
        local view = require("iron.view")
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
                repl_filetype = function(bufnr, ft)
                    return ft
                end,
                repl_open_cmd = view.split.horizontal.botright("40%"),
            },
            keymaps = {
                toggle_repl = "<leader>gr", -- toggles the repl open and closed.
                -- If repl_open_command is a table as above, then the following keymaps are
                -- available
                -- toggle_repl_with_cmd_1 = "<leader>rv",
                -- toggle_repl_with_cmd_2 = "<leader>rh",
                restart_repl = "<leader>rR", -- calls `IronRestart` to restart the repl
                send_motion = "<leader>st",
                visual_send = "<leader>sc",
                send_file = "<leader>sf",
                send_line = "<leader>sl",
                send_paragraph = "<leader>sp",
                send_until_cursor = "<leader>su",
                send_mark = "<leader>sm",
                send_code_block = "<leader>sb",
                send_code_block_and_move = "<leader>sn",
                mark_motion = "<leader>mc",
                mark_visual = "<leader>mc",
                remove_mark = "<leader>md",
                cr = "<leader>s<cr>",
                interrupt = "<leader>s<leader>",
                exit = "<leader>sq",
                clear = "<leader>cl",
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
