return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "latte",
            auto_integrations = true,
            -- Let Alacritty's window.opacity (and Hyprland's blur) show through:
            -- clears the bg on Normal and friends instead of painting C.base.
            transparent_background = true,
        })
        vim.cmd.colorscheme("catppuccin")
    end,
}
