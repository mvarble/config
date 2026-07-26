import QtQuick
import QtCore
import "MouseMap.js" as MouseMap
import "."

// SDDM theme entry point. The swarm of rats idles at fixed spawn
// locations until the mouse moves; then they wiggle their way over.
// Theme settings come from theme.conf via the greeter's `config`.
Item {
    id: root

    readonly property color backgroundColor: config.stringValue("backgroundColor") || "#101018"
    readonly property string backgroundImage: {
        const raw = config.stringValue("backgroundImage") || ""
        // Qt.resolvedUrl doesn't expand "~", so do it ourselves.
        if (raw.startsWith("~/"))
            return StandardPaths.writableLocation(StandardPaths.HomeLocation) + raw.substring(1)
        return raw
    }
    readonly property int ratCount: parseInt(config.stringValue("ratCount")) || 6
    readonly property real ratScaleMin: parseFloat(config.stringValue("ratScaleMin")) || 3.0
    readonly property real ratScaleMax: parseFloat(config.stringValue("ratScaleMax")) || 5.0
    readonly property real scareRadius: parseFloat(config.stringValue("scareRadius")) || 5.0
    readonly property real scareStrength: parseFloat(config.stringValue("scareStrength")) || 14.0
    // Scene, camera, and lighting
    readonly property real cameraFov: parseFloat(config.stringValue("cameraFov")) || 60.0
    readonly property real lightBrightness: parseFloat(config.stringValue("lightBrightness")) || 1.0
    readonly property real fillBrightness: parseFloat(config.stringValue("fillBrightness")) || 0.35
    // Swarm motion feel
    readonly property real ratMaxSpeed: parseFloat(config.stringValue("ratMaxSpeed")) || 8.0
    readonly property real springStiffness: parseFloat(config.stringValue("springStiffness")) || 8.0
    readonly property real springDamping: parseFloat(config.stringValue("springDamping")) || 5.0
    readonly property real rotationStiffness: parseFloat(config.stringValue("rotationStiffness")) || 6.0
    readonly property real wiggleAmplitude: parseFloat(config.stringValue("wiggleAmplitude")) || 0.10
    readonly property real wiggleWavelength: parseFloat(config.stringValue("wiggleWavelength")) || 0.8

    Rectangle {
        anchors.fill: parent
        color: root.backgroundColor
    }

    Image {
        id: bgImage
        anchors.fill: parent
        source: root.backgroundImage.length > 0 ? Qt.resolvedUrl(root.backgroundImage) : ""
        fillMode: Image.PreserveAspectCrop
        // Images smaller than the screen tile at natural size; larger
        // ones are cropped to fill. Decided imperatively (a binding
        // loops against the item size) and re-evaluated on resize,
        // since the image may finish loading before the window has
        // its final size.
        function updateFillMode() {
            if (status === Image.Ready && width > 0 && height > 0)
                fillMode = (sourceSize.width < width || sourceSize.height < height)
                           ? Image.Tile : Image.PreserveAspectCrop
        }
        onStatusChanged: updateFillMode()
        onWidthChanged: updateFillMode()
        onHeightChanged: updateFillMode()
        visible: source != "" && status === Image.Ready
    }

    RatScene {
        id: scene
        anchors.fill: parent
        ratCount: root.ratCount
        ratScaleMin: root.ratScaleMin
        ratScaleMax: root.ratScaleMax
        ratMaxSpeed: root.ratMaxSpeed
        springStiffness: root.springStiffness
        springDamping: root.springDamping
        rotationStiffness: root.rotationStiffness
        wiggleAmplitude: root.wiggleAmplitude
        wiggleWavelength: root.wiggleWavelength
        cameraFov: root.cameraFov
        lightBrightness: root.lightBrightness
        fillBrightness: root.fillBrightness
        // The login panel occupies the left edge of the screen; keep the
        // rats out of that region with a wall at its right edge.
        wallNdcX: 2.0 * loginPanel.width / root.width - 1.0
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: mouse => {
            const t = MouseMap.screenToTarget(mouse.x, mouse.y, width, height,
                                              scene.cameraZ, scene.cameraFov,
                                              scene.shellDistance)
            scene.pack.target = Qt.vector3d(t.x, t.y, t.z)
        }
        // Clicking startles the rats away from the click point; they
        // return to chasing the cursor right after.
        onClicked: mouse => {
            const t = MouseMap.screenToTarget(mouse.x, mouse.y, width, height,
                                              scene.cameraZ, scene.cameraFov,
                                              scene.shellDistance)
            scene.pack.scare(Qt.vector3d(t.x, t.y, t.z), root.scareRadius, root.scareStrength)
        }
    }

    FrameAnimation {
        running: true
        onTriggered: scene.pack.advance(frameTime)
    }

    LoginPanel {
        id: loginPanel
        blurSource: bgImage
    }
}
