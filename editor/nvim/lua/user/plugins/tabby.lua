return {
    "tzachar/cmp-ai",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
        local cmp_ai = require("cmp_ai.config")
        cmp_ai:setup({
            max_lines = 1000,
            provider = "Tabby",
            notify = true,
            provider_options = { user = "matthew@rodent.club" },
            notify_callback = function(msg)
                vim.notify(msg)
            end,
            run_on_every_keystroke = true,
        })
    end,
}
