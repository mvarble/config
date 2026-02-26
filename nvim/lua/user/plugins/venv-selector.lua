return {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
        "neovim/nvim-lspconfig",
        { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    ft = "python",
    lazy = false,
    keys = {
        { "<leader>vs", "<cmd>VenvSelect<cr>" },
    },
    opts = {
        options = {
            statusline_func = {
                nvchad = nil,
                lualine = function()
                    local venv_path = require("venv-selector").venv()
                    if not venv_path or venv_path == "" then
                        return ""
                    end
                    local venv_name = vim.fn.fnamemodify(venv_path, ":t")
                    if venv_name == "" then
                        return ""
                    elseif venv_name == ".venv" then
                        return vim.fn.fnamemodify(venv_path, ":h:t")
                    else
                        return venv_name
                    end
                end,
            },
        },
    },
}
