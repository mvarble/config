return {
    "mfussenegger/nvim-dap",
    dependencies = {
        {
            "mfussenegger/nvim-dap-python",
            config = function()
                -- Configure DAP commands
                local dap = require("dap")
                dap.configurations.python = {
                    {
                        type = "python",
                        request = "launch",
                        name = "Launch file",
                        program = "${file}",
                        justMyCode = false,
                    },
                }
                vim.keymap.set("n", "<leader>dd", dap.continue, { desc = "Start/Continue debugging" })
                vim.keymap.set("n", "<leader>d<Space>", dap.toggle_breakpoint, { desc = "Toggle debugger breakpoint" })
                vim.keymap.set("n", "<leader>dj", dap.step_over, { desc = "Step debugger over line." })
                vim.keymap.set("n", "<leader>dl", dap.step_into, { desc = "Step debugger into line." })
                vim.keymap.set("n", "<leader>dk", dap.step_out, { desc = "Step debugger out of line." })
                vim.keymap.set("n", "<leader>dr", function()
                    local repl_bufnr = nil

                    -- Find the REPL buffer if it exists
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_get_name(buf):match("%[dap%-repl%-%d+%]$") then
                            repl_bufnr = buf
                            break
                        end
                    end

                    if repl_bufnr and vim.api.nvim_buf_is_loaded(repl_bufnr) then
                        -- If the REPL is visible in a window, close it
                        for _, win in ipairs(vim.api.nvim_list_wins()) do
                            if vim.api.nvim_win_get_buf(win) == repl_bufnr then
                                vim.api.nvim_win_close(win, true)
                                return
                            end
                        end
                    end

                    -- Otherwise, open it
                    dap.repl.open()
                end, { desc = "Open debugger REPL" })

                -- select Python path
                local update_dap = function()
                    local venv = os.getenv("VIRTUAL_ENV")
                    local python_path = venv and (venv .. "/bin/python") or "python3"
                    require("dap-python").setup(python_path)
                end
                update_dap()

                -- create auto-command to select Python path
                vim.api.nvim_create_autocmd("User", {
                    pattern = "VenvActivated",
                    callback = update_dap,
                })
            end,
        },
    },
}
