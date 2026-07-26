import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

// Minimal, functional SDDM login panel: a full-height strip clamped to
// the left edge of the screen, with the inputs centered inside it.
// The backdrop is a colorless frosted-glass blur of the background
// image (falling back to a translucent dark box when there is none).
// Uses the greeter's context properties: sddm, userModel, sessionModel,
// config.
Item {
    id: panel

    // The full-screen background item to blur behind the panel.
    property var blurSource: null
    readonly property color accent: config.stringValue("accent") || "#7aa2f7"
    // Clock (time) typography; empty font = system default
    readonly property string timeFont: config.stringValue("timeFont") || ""
    readonly property int timeFontSize: parseInt(config.stringValue("timeFontSize")) || 28
    readonly property color timeColor: config.stringValue("timeColor") || "#ffffff"
    // Date typography; empty font = system default
    readonly property string dateFont: config.stringValue("dateFont") || ""
    readonly property int dateFontSize: parseInt(config.stringValue("dateFontSize")) || 14
    readonly property color dateColor: config.stringValue("dateColor") || "#ffffff"
    readonly property real dateOpacity: config.stringValue("dateOpacity") !== ""
                                        ? parseFloat(config.stringValue("dateOpacity")) : 0.7
    readonly property color inputColor: config.stringValue("inputColor") || "#ffffff"
    readonly property int inputFontSize: parseInt(config.stringValue("inputFontSize")) || 13
    readonly property bool buttonFill: {
        const v = (config.stringValue("buttonFill") || "").toLowerCase()
        return v === "true" || v === "1" || v === "yes" || v === "on"
    }
    readonly property color dimmedInputColor: Qt.rgba(inputColor.r, inputColor.g, inputColor.b, 0.55)
    // Highlight colors when hovering/focusing controls. Defaults keep
    // the previous behavior: accent border, slightly lightened fill.
    readonly property color hoverBorderColor: config.stringValue("hoverBorderColor") || panel.accent
    readonly property color hoverFillColor: config.stringValue("hoverFillColor") || Qt.lighter(panel.accent, 1.15)
    // Input fields: border and background (empty = accent-derived defaults;
    // "transparent" and #AARRGGBB are valid values)
    readonly property color inputBorderColor: config.stringValue("inputBorderColor")
                                              || Qt.rgba(accent.r, accent.g, accent.b, 0.35)
    readonly property color inputBackgroundColor: config.stringValue("inputBackgroundColor") || "transparent"
    // Buttons: font, border, and background. Empty values fall back to
    // buttonFill-derived defaults.
    readonly property color buttonBorderColor: config.stringValue("buttonBorderColor")
                                               || Qt.rgba(accent.r, accent.g, accent.b, 0.35)
    readonly property color buttonBackgroundColor: config.stringValue("buttonBackgroundColor")
                                                   || (buttonFill ? accent : "transparent")
    readonly property color buttonHoverBackgroundColor: config.stringValue("buttonHoverBackgroundColor")
                                                        || (buttonFill ? hoverFillColor : buttonBackgroundColor)
    readonly property color buttonTextColor: config.stringValue("buttonTextColor")
                                             || (buttonFill ? "white" : accent)
    // Panel layout and glass
    readonly property real panelWidthRatio: parseFloat(config.stringValue("panelWidthRatio")) || 0.16
    readonly property int panelMinWidth: parseInt(config.stringValue("panelMinWidth")) || 240
    readonly property color panelColor: config.stringValue("panelColor") || "#cc14141c"
    readonly property int controlRadius: parseInt(config.stringValue("controlRadius")) || 4
    readonly property int blurRadius: parseInt(config.stringValue("blurRadius")) || 48
    readonly property color errorColor: config.stringValue("errorColor") || "#f7768e"

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: Math.max(parent.width * panelWidthRatio, panelMinWidth)

    // Fallback when there is no background image to blur.
    Rectangle {
        anchors.fill: parent
        color: panel.panelColor
        border.color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.4)
        visible: !frost.visible
    }

    // Frosted glass: the background is first cropped to exactly the
    // panel's strip, then blurred with edge clamping and no transparent
    // padding. The blur therefore never samples pixels from outside the
    // panel, and the boundary between blurred and sharp stays a hard
    // line. (The strip source also renders underneath, but the blur is
    // fully opaque on top of it.)
    Item {
        id: frost
        anchors.fill: parent
        visible: panel.blurSource && panel.blurSource.status === Image.Ready

        ShaderEffectSource {
            id: stripSource
            anchors.fill: parent
            sourceItem: panel.blurSource
            sourceRect: Qt.rect(0, 0, width, height)
        }

        MultiEffect {
            anchors.fill: parent
            source: stripSource
            blurEnabled: true
            blur: 1.0
            blurMax: panel.blurRadius
            autoPaddingEnabled: false
        }
    }

    function tryLogin() {
        errorText.text = ""
        sddm.login(userField.text, passwordField.text, sessionBox.currentIndex)
    }

    // Shared look for all controls in the panel: fully configurable
    // normal/active background and border colors.
    component BorderedBackground: Rectangle {
        property bool active: false
        property color normalColor: "transparent"
        property color activeColor: normalColor
        property color normalBorder: panel.inputBorderColor
        property color activeBorder: panel.hoverBorderColor
        color: active ? activeColor : normalColor
        radius: panel.controlRadius
        border.width: 1
        border.color: active ? activeBorder : normalBorder
    }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 12

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            Text {
                id: clockText
                Layout.alignment: Qt.AlignHCenter
                color: panel.timeColor
                font.family: panel.timeFont
                font.pixelSize: panel.timeFontSize
            }

            Text {
                id: dateText
                Layout.alignment: Qt.AlignHCenter
                color: panel.dateColor
                opacity: panel.dateOpacity
                font.family: panel.dateFont
                font.pixelSize: panel.dateFontSize
            }
        }

        TextField {
            id: userField
            Layout.fillWidth: true
            placeholderText: "Username"
            text: userModel.lastUser
            color: panel.inputColor
            font.pixelSize: panel.inputFontSize
            placeholderTextColor: panel.dimmedInputColor
            background: BorderedBackground {
                active: userField.activeFocus
                normalColor: panel.inputBackgroundColor
            }
            onAccepted: passwordField.forceActiveFocus()
        }

        TextField {
            id: passwordField
            Layout.fillWidth: true
            placeholderText: "Password"
            echoMode: TextInput.Password
            color: panel.inputColor
            font.pixelSize: panel.inputFontSize
            placeholderTextColor: panel.dimmedInputColor
            background: BorderedBackground {
                active: passwordField.activeFocus
                normalColor: panel.inputBackgroundColor
            }
            onAccepted: panel.tryLogin()
        }

        ComboBox {
            id: sessionBox
            Layout.fillWidth: true
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
            font.pixelSize: panel.inputFontSize
            background: BorderedBackground {
                active: sessionBox.hovered || sessionBox.activeFocus
                normalColor: panel.inputBackgroundColor
            }
            contentItem: Text {
                text: sessionBox.displayText
                color: panel.inputColor
                font.pixelSize: panel.inputFontSize
                verticalAlignment: Text.AlignVCenter
                leftPadding: 8
                elide: Text.ElideRight
            }
            indicator: Text {
                text: "▾"
                color: panel.dimmedInputColor
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Button {
            id: loginButton
            Layout.fillWidth: true
            text: "Log In"
            background: BorderedBackground {
                active: loginButton.hovered || loginButton.activeFocus
                normalColor: panel.buttonBackgroundColor
                activeColor: panel.buttonHoverBackgroundColor
                normalBorder: panel.buttonBorderColor
            }
            contentItem: Text {
                text: loginButton.text
                color: panel.buttonTextColor
                font.pixelSize: panel.inputFontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: panel.tryLogin()
        }

        Text {
            id: errorText
            Layout.fillWidth: true
            color: panel.errorColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: text.length > 0
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Button {
                id: rebootButton
                text: "Reboot"
                visible: sddm.canReboot
                background: BorderedBackground {
                    active: rebootButton.hovered || rebootButton.activeFocus
                    normalColor: panel.buttonBackgroundColor
                    activeColor: panel.buttonHoverBackgroundColor
                    normalBorder: panel.buttonBorderColor
                }
                contentItem: Text {
                    text: rebootButton.text
                    color: panel.buttonTextColor
                    font.pixelSize: panel.inputFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: sddm.reboot()
            }
            Button {
                id: powerButton
                text: "Power Off"
                visible: sddm.canPowerOff
                background: BorderedBackground {
                    active: powerButton.hovered || powerButton.activeFocus
                    normalColor: panel.buttonBackgroundColor
                    activeColor: panel.buttonHoverBackgroundColor
                    normalBorder: panel.buttonBorderColor
                }
                contentItem: Text {
                    text: powerButton.text
                    color: panel.buttonTextColor
                    font.pixelSize: panel.inputFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: sddm.powerOff()
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = qsTr("Login failed, please try again")
            passwordField.clear()
            passwordField.forceActiveFocus()
        }
    }

    function updateClock() {
        const now = new Date()
        clockText.text = Qt.formatTime(now, "HH:mm")
        dateText.text = Qt.formatDate(now, "dddd, MMMM d")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: panel.updateClock()
    }

    Component.onCompleted: {
        if (userField.text.length > 0)
            passwordField.forceActiveFocus()
        else
            userField.forceActiveFocus()
    }
}
