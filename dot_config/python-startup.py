from _colorize import ANSIColors, Syntax, default_theme, set_theme


def _main():
    """Everything's in a function to avoid polluting the global scope."""

    # Define Solarized Light colors
    solarized_light_theme = default_theme.copy_with(
        syntax=Syntax(
            keyword=ANSIColors.GREEN,
            builtin=ANSIColors.BLUE,
            comment=ANSIColors.BLUE,
            string=ANSIColors.CYAN,
            number=ANSIColors.CYAN,
            definition=ANSIColors.BOLD_BLUE,
            soft_keyword=ANSIColors.BOLD_GREEN,
            op=ANSIColors.RESET,
            reset=ANSIColors.RESET,
        ),
    )
    set_theme(solarized_light_theme)


_main()  # _main avoids name collision, in case python -i is used
del _main  # Delete _main from global scope
