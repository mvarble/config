local chat = {
    term_buf = nil, -- terminal buffer running aichat
    term_job = nil, -- terminal job ID
    prompt_buf = nil, -- prompt buffer
}

local function open_chat()
    -- If the window is open, close it
    if chat.term_buf then
        local term_win = vim.fn.bufwinid(chat.term_buf)
        if term_win and vim.api.nvim_win_is_valid(term_win) then
            vim.api.nvim_win_close(term_win, true)
            if chat.prompt_buf then
                local prompt_win = vim.fn.bufwinid(chat.prompt_buf)
                if prompt_win and vim.api.nvim_win_is_valid(prompt_win) then
                    vim.api.nvim_win_close(prompt_win, true)
                end
            end
            return
        end
    end

    -- Create the aichat terminal buffer if not running
    if not (chat.term_buf and vim.api.nvim_buf_is_valid(chat.term_buf)) then
        vim.cmd("botright vsplit") -- open split for chat log
        vim.cmd("enew") -- new empty buffer
        chat.term_buf = vim.api.nvim_get_current_buf()
        chat.term_job = vim.fn.jobstart("aichat", { term = true }) -- run inside this buffer
        vim.bo[chat.term_buf].bufhidden = "hide"
    else
        vim.cmd("botright vsplit")
        vim.api.nvim_win_set_buf(0, chat.term_buf)
    end

    -- Create prompt buffer
    chat.prompt_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[chat.prompt_buf].filetype = "markdown"
    vim.bo[chat.prompt_buf].buftype = "acwrite"
    vim.bo[chat.prompt_buf].bufhidden = "wipe"
    vim.bo[chat.prompt_buf].swapfile = false
    vim.api.nvim_buf_set_name(chat.prompt_buf, "AI Prompt")

    -- Put prompt buffer in a horizontal split below
    vim.cmd("belowright split")
    vim.api.nvim_win_set_buf(0, chat.prompt_buf)

    -- Intercept :w to send to aichat
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = chat.prompt_buf,
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(chat.prompt_buf, 0, -1, false)
            local prompt = table.concat(lines, "\n")
            if prompt:match("%S") then
                vim.fn.chansend(chat.term_job, prompt)
                vim.api.nvim_buf_set_lines(chat.prompt_buf, 0, -1, false, {})
            end

            -- Force jump back to prompt buffer split
            vim.defer_fn(function()
                local term_win = vim.fn.bufwinid(chat.term_buf)
                if term_win ~= -1 then
                    vim.api.nvim_set_current_win(term_win)
                    vim.cmd("startinsert")
                    local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
                    vim.api.nvim_feedkeys(cr, "n", false)
                    vim.defer_fn(function()
                        vim.cmd("stopinsert")
                        local prompt_win = vim.fn.bufwinid(chat.prompt_buf)
                        if prompt_win ~= -1 then
                            vim.api.nvim_set_current_win(prompt_win)
                        end
                    end, 20)
                end
            end, 10)
        end,
    })
end

vim.keymap.set("n", "<leader>c", open_chat, { desc = "Open AI chat (terminal + prompt)" })
