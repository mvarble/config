import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Thin bottom card listing the existing Hyprland workspaces, with the focused
// one highlighted. Flashes for a moment whenever the focused workspace
// changes; also controllable via `qs ipc call workspacebar open/close`.
PanelWindow {
    id: root

    property bool open: false

    // Last focused workspace seen; the first change after startup only primes
    // it so the bar doesn't flash on login.
    property var lastWorkspace: null

    // How long the bar stays visible after a workspace switch.
    readonly property int flashDuration: 1000

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            const ws = Hyprland.focusedWorkspace;
            if (root.lastWorkspace && ws && ws !== root.lastWorkspace) {
                root.open = true;
                hideTimer.restart();
            }
            root.lastWorkspace = ws;
        }
    }

    Timer {
        id: hideTimer
        interval: root.flashDuration
        onTriggered: root.open = false
    }

    anchors {
        left: true
        right: true
        bottom: true
    }
    implicitHeight: card.implicitHeight + 12
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: open

    WlrLayershell.namespace: "quickshell-workspacebar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Display-only: accept no input anywhere so the strip never swallows
    // clicks (SUPER+LMB/RMB window drags must keep working while it's up).
    mask: Region {}

    // Existing workspaces with positive ids (excludes special/scratchpad
    // workspaces), sorted numerically.
    // Workspace 10 is persistent and pinned to the alt monitor; hide it.
    readonly property var workspaceList: {
        const list = [];
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > 0 && ws.id !== 10)
                list.push(ws);
        return list.sort((a, b) => a.id - b.id);
    }

    Rectangle {
        id: card
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 0
        }
        implicitWidth: row.implicitWidth + 20
        implicitHeight: row.implicitHeight + 14
        radius: Theme.radius
        color: Theme.cardBackground
        border.color: Theme.cardBorder

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: root.workspaceList

                delegate: Rectangle {
                    required property var modelData // HyprlandWorkspace

                    width: 34
                    height: 34
                    radius: 8
                    color: modelData.focused ? Theme.accent : "transparent"
                    border.color: modelData.focused ? Theme.accent : Theme.cardBorder

                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: modelData.focused ? "#ffffff" : Theme.text
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }
    }
}
