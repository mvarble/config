function fish_prompt
    if test -n "$SSH_TTY"
        echo -n (set_color brblue)"$USER"(set_color white)'@'(set_color green)(prompt_hostname)' '
    end

    echo -n (set_color purple)(prompt_pwd)' '

    set_color -o
    if fish_is_root_user
        echo -n (set_color red)'# '
    end
    echo -n (set_color blue)'❯ '
    set_color normal
end
