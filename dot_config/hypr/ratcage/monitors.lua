local main = "DP-1"
local alt = "HDMI-A-1"

hl.monitor({
    output = main,
    mode = "preferred",
    position = "0x0",
    scale = "1",
})
hl.monitor({
    output = alt,
    mode = "1280x720",
    position = "-100x-720",
    scale = "1",
})
hl.config({
    cursor = {
        default_monitor = "DP-1",
    },
})

return { main = main, alt = alt }
