import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "services"

// Centered modal launcher. Searches desktop applications; falls back to
// running the typed text as a shell command. Toggled via
// `qs ipc call launcher toggle`.
PanelWindow {
    id: root

    property bool open: false

    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: open

    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""

    function appRow(entry) {
        return { isCommand: false, name: entry.name, icon: entry.icon, entry: entry };
    }

    // Empty-query rows: the most frequently/recently launched apps and
    // commands, learned by LaunchHistory. Falls back to a plain app slice
    // until anything has been launched.
    function suggestionRows() {
        const apps = DesktopEntries.applications.values;
        const rows = [];
        for (const id of LaunchHistory.topIds(8)) {
            if (id.startsWith("cmd:"))
                rows.push({ isCommand: true, name: id.slice(4), icon: "", entry: null });
            else {
                const entry = apps.find(a => a.id === id);
                if (entry && !entry.noDisplay)
                    rows.push(appRow(entry));
            }
        }
        return rows;
    }

    // Rows shown in the result list. Empty query: learned suggestions.
    // Otherwise: name matches ranked by frecency, plus a trailing
    // "run as command" row.
    readonly property var items: {
        const q = query.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        if (q === "") {
            const suggestions = suggestionRows();
            return suggestions.length > 0 ? suggestions : apps.slice(0, 8).map(appRow);
        }
        const rows = apps
            .filter(e => e.name.toLowerCase().includes(q))
            .map(e => ({ isCommand: false, name: e.name, icon: e.icon, entry: e, s: LaunchHistory.score(e.id) }))
            .sort((a, b) => (b.s - a.s) || a.name.localeCompare(b.name))
            .slice(0, 7);
        rows.push({ isCommand: true, name: query.trim(), icon: "", entry: null });
        return rows;
    }

    onOpenChanged: {
        if (open) {
            query = "";
            field.clear();
            list.currentIndex = 0;
            field.forceActiveFocus();
        }
    }

    function activate(index) {
        const item = items[index];
        if (!item)
            return;
        if (item.isCommand) {
            LaunchHistory.record("cmd:" + item.name);
            Quickshell.execDetached(["sh", "-c", item.name]);
        } else {
            LaunchHistory.record(item.entry.id);
            item.entry.execute();
        }
        root.open = false;
    }

    // Dimmed backdrop; clicking it closes the modal.
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    // Centered modal box, styled like the settings panel's cards.
    Rectangle {
        id: modal
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -60
        width: 560
        height: 460
        radius: Theme.radius
        color: Theme.cardBackground
        border.color: Theme.cardBorder

        // Absorb clicks so the backdrop doesn't close when clicking inside.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 10

            TextField {
                id: field
                Layout.fillWidth: true
                focus: true
                placeholderText: "Search applications or run a command…"
                color: Theme.text
                placeholderTextColor: Theme.subtext
                font.pixelSize: Theme.fontSize

                background: Rectangle {
                    radius: 8
                    color: Theme.surfaceAlt
                    border.color: field.activeFocus ? Theme.accent : Theme.cardBorder
                }

                onTextChanged: {
                    root.query = text;
                    list.currentIndex = 0;
                }
                onAccepted: root.activate(list.currentIndex)
                Keys.onUpPressed: list.decrementCurrentIndex()
                Keys.onDownPressed: list.incrementCurrentIndex()
                Keys.onEscapePressed: root.open = false
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.items
                currentIndex: 0

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: list.width
                    height: 44
                    radius: 8
                    color: list.currentIndex === index ? Theme.surfaceAlt : "transparent"

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 10

                        IconImage {
                            visible: !modelData.isCommand
                            source: modelData.isCommand ? "" : Quickshell.iconPath(modelData.icon, true)
                            implicitSize: 22
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.isCommand ? "Run command: " + modelData.name : modelData.name
                            color: Theme.text
                            font.pixelSize: Theme.fontSize
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: root.activate(index)
                    }
                }
            }
        }
    }
}
