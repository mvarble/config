hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "caps:super",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        repeat_rate = 100,
        repeat_delay = 350,
        touchpad = {
            clickfinger_behavior = true,
            natural_scroll = true,
            tap_to_click = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
