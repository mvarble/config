import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services"

// Top-sliding card with a month view and a day view of CalDAV events
// (read-only; see services/Calendar.qml). Toggled via
// `qs ipc call calendar toggle`.
PanelWindow {
    id: root

    property bool open: false

    // Close choreography mirrors SettingsPanel: `open` is the toggle target.
    // On close, the card slides up first and only then does the window unmap
    // (`shown` -> false via closeTimer).
    property bool shown: false
    property bool cardIn: false

    onOpenChanged: {
        if (open) {
            closeTimer.stop();
            shown = true;
            cardIn = true;
            goToday();
            Calendar.refresh();
        } else {
            cardIn = false;
            closeTimer.restart();
        }
    }

    onCardInChanged: {
        enterAnim.stop();
        exitAnim.stop();
        if (cardIn) {
            drop.y = -card.travel;
            card.opacity = 0;
            enterAnim.restart();
        } else {
            exitAnim.restart();
        }
    }

    // Exit bounce (350 ms) plus a little slack before unmapping.
    Timer {
        id: closeTimer
        interval: 380
        onTriggered: root.shown = false
    }

    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: shown

    WlrLayershell.namespace: "quickshell-calendar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Selected day and the month currently displayed by the grid.
    property date selectedDate: new Date()
    property date displayedMonth: new Date(new Date().getFullYear(), new Date().getMonth(), 1)

    // First day of the week in JS convention (Sunday = 0). Fixed to Monday
    // rather than the locale default.
    readonly property int firstDow: 1

    function goToday() {
        const now = new Date();
        selectedDate = now;
        displayedMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    }

    function shiftMonth(delta) {
        displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + delta, 1);
    }

    // 42 cells covering the displayed month plus leading/trailing days.
    function monthCells() {
        const y = displayedMonth.getFullYear();
        const m = displayedMonth.getMonth();
        const off = (new Date(y, m, 1).getDay() - firstDow + 7) % 7;
        const first = new Date(y, m, 1 - off);
        const cells = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(first.getFullYear(), first.getMonth(), first.getDate() + i);
            cells.push({ date: d, inMonth: d.getMonth() === m });
        }
        return cells;
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    // Stable color per calendar name for the day-view event bars.
    readonly property var palette: [Theme.accent, Theme.ok, "#af52de", "#ff9f0a", Theme.warn, Theme.crit]

    function calendarColor(name) {
        let h = 0;
        for (let i = 0; i < name.length; i++)
            h = (h * 31 + name.charCodeAt(i)) >>> 0;
        return palette[h % palette.length];
    }

    // Backdrop: clicking outside the card closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Rectangle {
        id: card
        width: 700
        height: 520
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        radius: Theme.radius
        color: Theme.cardBackground
        border.color: Theme.cardBorder
        opacity: 0

        // Enter/exit bounce mirrors the settings sections: a short vertical
        // travel with a back-eased overshoot plus a fade. Applied via a
        // Translate transform so it does not fight the card's y position.
        readonly property int travel: 24

        transform: Translate {
            id: drop
            y: -card.travel
        }

        SequentialAnimation {
            id: enterAnim

            ParallelAnimation {
                NumberAnimation {
                    target: drop
                    property: "y"
                    to: 0
                    duration: 500
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.4
                }

                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 1
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }

        SequentialAnimation {
            id: exitAnim

            ParallelAnimation {
                NumberAnimation {
                    target: drop
                    property: "y"
                    to: -card.travel
                    duration: 350
                    easing.type: Easing.InBack
                    easing.overshoot: 1.4
                }

                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 0
                    duration: 200
                    easing.type: Easing.InCubic
                }
            }
        }

        focus: true
        Keys.onEscapePressed: root.open = false

        // Absorb clicks so the backdrop doesn't close when clicking inside.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        RowLayout {
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 16

            // ------------------------- Month view -------------------------
            // Fixed column widths: elided text still reports its full implicit
            // width, which would otherwise let the day view steal space from
            // the month grid.
            ColumnLayout {
                Layout.fillHeight: true
                Layout.minimumWidth: 380
                Layout.preferredWidth: 380
                Layout.maximumWidth: 380
                spacing: 8

                // Header: month title + navigation.
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: root.displayedMonth.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                        color: Theme.text
                        font.pixelSize: Theme.titleSize
                        font.bold: true
                    }

                    Repeater {
                        model: [
                            { label: "‹", delta: -1 },
                            { label: "Today", delta: 0 },
                            { label: "›", delta: 1 }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            width: navLabel.implicitWidth + 16
                            height: 26
                            radius: 8
                            color: navMa.containsMouse ? Theme.surfaceAlt : "transparent"

                            Text {
                                id: navLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: Theme.text
                                font.pixelSize: Theme.fontSize - 2
                            }

                            MouseArea {
                                id: navMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: modelData.delta === 0 ? root.goToday() : root.shiftMonth(modelData.delta)
                            }
                        }
                    }
                }

                // Weekday header, ordered by the locale's first day of week.
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 2

                    Repeater {
                        model: 7

                        delegate: Text {
                            required property int index
                            readonly property int qtDow: (root.firstDow + index) % 7 || 7

                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.locale().dayName(qtDow, Locale.ShortFormat)
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }
                }

                // Day cells.
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    columnSpacing: 2
                    rowSpacing: 2

                    Repeater {
                        model: root.monthCells()

                        delegate: Rectangle {
                            id: cell
                            required property var modelData
                            readonly property bool isToday: root.sameDay(modelData.date, new Date())
                            readonly property bool isSelected: root.sameDay(modelData.date, root.selectedDate)

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: isToday ? Theme.accent : (isSelected ? Theme.surfaceAlt : "transparent")
                            border.color: isSelected && !isToday ? Theme.accent : "transparent"
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: cell.modelData.date.getDate()
                                    font.pixelSize: Theme.fontSize
                                    color: cell.isToday ? "#ffffff" : (cell.modelData.inMonth ? Theme.text : Theme.subtext)
                                    opacity: cell.modelData.inMonth ? 1 : Theme.mutedOpacity
                                }

                                // Dot marking days that have events.
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 4
                                    height: 4
                                    radius: 2
                                    visible: Calendar.hasEvents(cell.modelData.date)
                                    color: cell.isToday ? "#ffffff" : Theme.accent
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.selectedDate = cell.modelData.date;
                                    if (!cell.modelData.inMonth)
                                        root.displayedMonth = new Date(cell.modelData.date.getFullYear(), cell.modelData.date.getMonth(), 1);
                                }
                            }
                        }
                    }
                }
            }

            // Separator.
            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Theme.cardBorder
            }

            // -------------------------- Day view --------------------------
            // 700 card - 2*16 margins - 2*16 spacing - 1 separator - 380 month.
            ColumnLayout {
                Layout.fillHeight: true
                Layout.minimumWidth: 255
                Layout.preferredWidth: 255
                Layout.maximumWidth: 255
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.selectedDate.toLocaleDateString(Qt.locale(), "dddd, MMMM d")
                    color: Theme.text
                    font.pixelSize: Theme.titleSize - 2
                    font.bold: true
                }

                // Sync status: hidden while everything is fine.
                Text {
                    Layout.fillWidth: true
                    visible: Calendar.lastError !== "" || Calendar.fetching
                    text: Calendar.lastError !== "" ? "Sync: " + Calendar.lastError : "Updating…"
                    color: Calendar.lastError !== "" ? Theme.crit : Theme.subtext
                    font.pixelSize: Theme.fontSize - 3
                    elide: Text.ElideRight
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: dayList
                        anchors.fill: parent
                        clip: true
                        spacing: 6
                        model: Calendar.eventsForDay(root.selectedDate)

                        delegate: Rectangle {
                            required property var modelData

                            width: dayList.width
                            height: eventRow.implicitHeight + 14
                            radius: 8
                            color: Theme.surfaceAlt

                            RowLayout {
                                id: eventRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 10
                                    rightMargin: 10
                                }
                                spacing: 8

                                // Start/end time, or "All day".
                                ColumnLayout {
                                    Layout.minimumWidth: 62
                                    Layout.preferredWidth: 62
                                    Layout.maximumWidth: 62
                                    spacing: 0

                                    Text {
                                        text: modelData.allDay ? "All day" : new Date(modelData.start).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                                        color: Theme.text
                                        font.pixelSize: Theme.fontSize - 3
                                    }
                                    Text {
                                        visible: !modelData.allDay
                                        text: new Date(modelData.end).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                                        color: Theme.subtext
                                        font.pixelSize: Theme.fontSize - 3
                                    }
                                }

                                Rectangle {
                                    Layout.fillHeight: true
                                    width: 3
                                    radius: 1.5
                                    color: root.calendarColor(modelData.calendar)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.summary
                                        color: Theme.text
                                        font.pixelSize: Theme.fontSize - 1
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: modelData.location !== ""
                                        text: modelData.location
                                        color: Theme.subtext
                                        font.pixelSize: Theme.fontSize - 3
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: dayList.count === 0
                        text: "No events"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }
    }
}
