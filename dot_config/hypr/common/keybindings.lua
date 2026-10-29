local programs = require("./common/programs")
local config = require("./common/config.lua")
local mainMod = config.mainMod
local workspaces = config.workspaces

-- Hyprland session
hl.bind(
    mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(programs.lock))

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

-- Scroll the strip so `window` sits where fit mode would put it: flush left, or flush right in the last column
local function refit(window)
    local has_column_right = false
    for _, other in ipairs(hl.get_windows({ workspace = window.workspace.id, floating = false })) do
        if other.at.x >= window.at.x + window.size.x then
            has_column_right = true
        end
    end
    -- Push the window just off-screen, then refocus it so fit mode scrolls it back flush with that edge
    local monitor = window.monitor
    local delta
    if has_column_right then
        delta = monitor.x - (window.at.x + window.size.x) - 1
    else
        delta = monitor.x + monitor.width - window.at.x + 1
    end
    hl.dispatch(hl.dsp.layout("move " .. delta))
    hl.dispatch(hl.dsp.focus({ window = window }))
end

-- Workspace ids whose strip keeps the focused column centered; every other workspace fits columns to the view
local centered = {}

-- Scroll the strip so `window` sits where its workspace's mode puts it
local function realign(window)
    if window.floating or window.fullscreen ~= 0 or not window.workspace then
        return
    end
    if centered[window.workspace.id] then
        -- Refocus so the strip centers immediately instead of on the next focus change
        hl.dispatch(hl.dsp.focus({ window = window }))
    else
        refit(window)
    end
end

-- scrolling.focus_fit_method is global, so match it to the active workspace; returns whether it changed
local function sync_fit_method()
    local workspace = hl.get_active_workspace()
    local method = (workspace and centered[workspace.id]) and 0 or 1
    if hl.get_config("scrolling.focus_fit_method") == method then
        return false
    end
    hl.config({ scrolling = { focus_fit_method = method } })
    return true
end

-- Toggle the active workspace between centering the focused column and fitting columns to the view
local function toggle_centered()
    local workspace = hl.get_active_workspace()
    if not workspace then
        return
    end
    centered[workspace.id] = not centered[workspace.id] or nil
    sync_fit_method()
    local window = hl.get_active_window()
    if window then
        realign(window)
    end
end
hl.bind("ALT + n", toggle_centered)

-- Focus landing on another workspace was scrolled with the previous workspace's mode, so redo it with this one's
hl.on("window.active", function(window)
    if sync_fit_method() and window then
        realign(window)
    end
end)
hl.on("workspace.active", sync_fit_method)
hl.on("monitor.focused", sync_fit_method)
-- Workspace ids get reused, so a recreated workspace starts out fitting
hl.on("workspace.created", function(workspace)
    centered[workspace.id] = nil
end)
-- A reload forgets which workspaces were centered, so drop back to fitting
sync_fit_method()

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
