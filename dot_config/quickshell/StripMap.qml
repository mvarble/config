import QtQuick
import Quickshell.Hyprland

// Minimap of the scrolling layout's strip on one monitor's active workspace.
// Every tiled window is a box at its true relative position and size, the
// workspace's focused window is filled with the accent color, and a frame
// marks the part of the strip currently on screen (the "camera"), so
// ALT+N's centering shows up as the frame sliding along the strip. Click a
// box to focus that window.
Item {
    id: root

    // HyprlandMonitor whose active workspace is drawn.
    property var monitor: null

    // Drawn width of the on-screen frame; everything else scales to match.
    readonly property real frameWidth: 96
    readonly property real mapHeight: 22
    readonly property real framePadding: 3

    readonly property var workspace: monitor?.activeWorkspace ?? null

    // Monitor area in layout coordinates.
    readonly property real viewX: monitor?.x ?? 0
    readonly property real viewY: monitor?.y ?? 0
    readonly property real viewW: monitor ? monitor.width / monitor.scale : 1
    readonly property real viewH: monitor ? monitor.height / monitor.scale : 1

    readonly property real scaleX: frameWidth / viewW
    readonly property real scaleY: mapHeight / viewH

    // Tiled windows on the workspace, from the last `clients` snapshot. The
    // focused one is the workspace's most recently focused window, so the
    // strip of an unfocused monitor still shows where its focus sits.
    readonly property var windows: {
        const list = [];
        for (const toplevel of workspace?.toplevels.values ?? []) {
            const ipc = toplevel.lastIpcObject;
            if (!ipc?.at || ipc.floating || ipc.hidden || !ipc.mapped)
                continue;
            list.push({
                toplevel: toplevel,
                x: ipc.at[0],
                y: ipc.at[1],
                w: ipc.size[0],
                h: ipc.size[1],
                history: ipc.focusHistoryID,
            });
        }
        const focused = Math.min(...list.map(w => w.history));
        for (const w of list)
            w.focused = w.history === focused;
        return list;
    }

    // Horizontal extent of the strip and the on-screen area together.
    readonly property real minX: Math.min(viewX, ...windows.map(w => w.x))
    readonly property real maxX: Math.max(viewX + viewW, ...windows.map(w => w.x + w.w))

    implicitWidth: (maxX - minX) * scaleX + 2 * framePadding
    implicitHeight: mapHeight + 2 * framePadding
    visible: windows.length > 0

    // Window geometry only arrives with a `clients` refresh, and the layout
    // scrolls on focus changes, so refresh after any event. The short delay
    // coalesces bursts (focus changes emit several events at once).
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            refreshTimer.restart();
        }
    }

    Timer {
        id: refreshTimer
        interval: 50
        onTriggered: Hyprland.refreshToplevels()
    }

    Component.onCompleted: Hyprland.refreshToplevels()

    Repeater {
        model: root.windows

        delegate: Rectangle {
            required property var modelData

            // Inset by a pixel so neighbouring columns stay distinct at this scale.
            x: root.framePadding + (modelData.x - root.minX) * root.scaleX + 1
            y: root.framePadding + (modelData.y - root.viewY) * root.scaleY
            width: Math.max(modelData.w * root.scaleX - 2, 2)
            height: Math.max(modelData.h * root.scaleY, 2)
            radius: 3
            // Card-colored and bordered like the workspace squares, so boxes
            // hold their shape whichever wallpaper the bar is frosting.
            color: modelData.focused ? Theme.accent : Theme.surface
            border.color: modelData.focused ? Theme.accent : Theme.cardBorder
            // Windows scrolled off screen fade back.
            opacity: modelData.x < root.viewX + root.viewW && modelData.x + modelData.w > root.viewX ? 1 : Theme.mutedOpacity

            MouseArea {
                anchors.fill: parent
                // Focusing warps the cursor onto the window, and the focus
                // dispatcher has no option against it, so suppress warps for
                // just this dispatch and leave the pointer on the bar.
                onClicked: {
                    const address = String(modelData.toplevel.address);
                    const selector = "address:" + (address.startsWith("0x") ? address : "0x" + address);
                    Hyprland.dispatch(`function()
                        local warps = hl.get_config("cursor.no_warps")
                        hl.config({ cursor = { no_warps = true } })
                        hl.dispatch(hl.dsp.focus({ window = "${selector}" }))
                        hl.config({ cursor = { no_warps = warps } })
                    end`);
                }
            }
        }
    }

    // The on-screen area.
    Rectangle {
        x: (root.viewX - root.minX) * root.scaleX
        width: root.frameWidth + 2 * root.framePadding
        height: root.mapHeight + 2 * root.framePadding
        radius: 6
        color: "transparent"
        border.color: Theme.text
        border.width: 1.5
    }
}
