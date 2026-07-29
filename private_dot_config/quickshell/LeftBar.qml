import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Thin persistent bar on the left screen edge showing the Hyprland
// workspaces (click to switch) above a ticking clock. Always visible and
// reserves screen space via the layer-shell exclusive zone, so tiled
// windows sit to its right.
PanelWindow {
    id: root

    anchors {
        left: true
        top: true
        bottom: true
    }
    implicitWidth: Theme.barWidth
    color: Theme.cardBackground
    exclusionMode: ExclusionMode.Auto

    WlrLayershell.namespace: "quickshell-leftbar"
    // Above the other shell surfaces (settings panel is Top layer) so their
    // cards slide out from behind the bar. The exclusive zone still applies.
    WlrLayershell.layer: WlrLayer.Overlay

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Existing workspaces with positive ids (excludes special/scratchpad
    // workspaces), sorted numerically.
    readonly property var workspaceList: {
        const list = [];
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > 0)
                list.push(ws);
        return list.sort((a, b) => a.id - b.id);
    }

    // Right-edge separator, standing in for the card borders used elsewhere.
    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: 1
        color: Theme.cardBorder
    }

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: 8
            bottomMargin: 8
        }
        spacing: 6

        Repeater {
            model: root.workspaceList

            delegate: Rectangle {
                required property var modelData // HyprlandWorkspace

                Layout.alignment: Qt.AlignHCenter
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
            Layout.fillHeight: true
        }

        // The 19-char datetime can't fit horizontally in a thin bar, so it
        // is rotated to read bottom-to-top. The wrapper Item swaps the
        // text's width/height so the layout reserves the right space.
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: clockText.height
            implicitHeight: clockText.width

            Text {
                id: clockText
                anchors.centerIn: parent
                rotation: -90
                text: Qt.formatDateTime(clock.date, "yyyy-MM-dd HH:mm:ss")
                color: Theme.text
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }
}
