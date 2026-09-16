import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Thin persistent bar along the top screen edge showing the Hyprland
// workspaces (click to switch) on the left and a ticking clock on the right.
// Reserves screen space via the layer-shell exclusive zone, so tiled windows
// sit below it. Hides itself while a window is fullscreened on this bar's
// monitor.
PanelWindow {
    id: root

    anchors {
        left: true
        top: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.cardBackground
    exclusionMode: ExclusionMode.Auto

    // True while the workspace shown on this bar's monitor has a fullscreen
    // client. Hiding the window destroys the layer surface, releasing the
    // exclusive zone until fullscreen is exited.
    readonly property bool fullscreenActive:
        Hyprland.monitorFor(root.screen)?.activeWorkspace?.hasFullscreen ?? false
    visible: !fullscreenActive

    WlrLayershell.namespace: "quickshell-topbar"
    // Overlay keeps the bar visible above the settings panel, which sits on
    // the Top layer. The exclusive zone still applies; the fullscreen check
    // above is what yields the screen to fullscreen windows.
    WlrLayershell.layer: WlrLayer.Overlay

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

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

    // Bottom-edge separator, standing in for the card borders used elsewhere.
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: Theme.cardBorder
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 6

        Repeater {
            model: root.workspaceList

            delegate: Rectangle {
                required property var modelData // HyprlandWorkspace

                Layout.alignment: Qt.AlignVCenter
                width: 28
                height: 28
                radius: 8
                color: modelData.focused ? Theme.accent : "transparent"
                border.color: modelData.focused ? Theme.accent : Theme.cardBorder

                Text {
                    anchors.centerIn: parent
                    text: modelData.name
                    color: modelData.focused ? "#ffffff" : Theme.text
                    font.pixelSize: Theme.fontSize
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: modelData.activate()
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatDateTime(clock.date, "yyyy-MM-dd HH:mm:ss")
            color: Theme.text
            font.pixelSize: Theme.fontSize - 2
        }
    }
}
