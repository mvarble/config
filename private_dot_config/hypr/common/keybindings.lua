local programs = require("./common/programs")
local config = require("./common/config.lua")
local mainMod = config.mainMod
local workspaces = config.workspaces

-- Hyprland session
hl.bind(
    mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Program shortcuts
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(programs.browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(programs.launcher))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(programs.settings))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(programs.calendar))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(programs.notifications))

-- Toggle floating/full
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

-- Move focus with ALT + vi keys
hl.bind("ALT + h", hl.dsp.focus({ direction = "left" }))
hl.bind("ALT + l", hl.dsp.focus({ direction = "right" }))
hl.bind("ALT + k", hl.dsp.focus({ direction = "up" }))
hl.bind("ALT + j", hl.dsp.focus({ direction = "down" }))

-- Move focus with ALT + SHIFT + vi keys
hl.bind("ALT + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind("ALT + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
hl.bind("ALT + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind("ALT + SHIFT + j", hl.dsp.window.move({ direction = "down" }))

-- Switch workspaces with mainMod + [1-N]
-- Move active window to a workspace with mainMod + SHIFT + [1-N]
for i = 1, workspaces do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Scroll through existing workspaces with mainMod + j/k
hl.bind(mainMod .. " + j", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
