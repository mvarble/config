import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils
import "MouseMap.js" as MouseMap
import RatMotion 1.0

// The 3D scene: a fixed camera, two lights, and the swarm of rats.
// Each rat binds its position/rotation to a RatMotion object owned by
// the RatPack; the pack handles steering, wiggle, and OBB collision
// between the rats.
//
// Note: the rats are loaded with RuntimeLoader because Model.source
// only accepts pre-baked .mesh files on Qt 6.11 (runtime glTF import
// was moved to QtQuick3D.AssetUtils).
Item {
    id: root

    property alias pack: pack
    property int ratCount: 6
    property real ratScaleMin: 3.0
    property real ratScaleMax: 5.0
    property real ratMaxSpeed: 8.0
    property real springStiffness: 8.0
    property real springDamping: 5.0
    property real rotationStiffness: 6.0
    property real wiggleAmplitude: 0.10
    property real wiggleWavelength: 0.8
    property real cameraZ: 10.0
    property real cameraFov: 60.0
    property real shellDistance: 9.0
    property real lightBrightness: 1.0
    property real fillBrightness: 0.35
    // Vertical screen-space line (NDC, -1..1) the rats may not cross.
    // Values below -1 disable the wall entirely.
    property real wallNdcX: -2.0
    readonly property real shellZ: cameraZ - shellDistance
    readonly property real wallX: wallNdcX < -1.0
        ? -1.0e9
        : MouseMap.ndcToWorldX(wallNdcX, shellZ, cameraZ, cameraFov,
                               width / Math.max(1, height))

    View3D {
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "transparent"
            backgroundMode: SceneEnvironment.Transparent
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 0, root.cameraZ)
            fieldOfView: root.cameraFov
            clipNear: 0.1
            clipFar: 100.0
        }

        DirectionalLight {
            eulerRotation.x: -35
            eulerRotation.y: -25
            brightness: root.lightBrightness
        }

        // Weak fill from behind/below so the low-poly facets read well.
        DirectionalLight {
            eulerRotation.x: 25
            eulerRotation.y: 150
            brightness: root.fillBrightness
        }

        Repeater3D {
            model: pack.rats

            delegate: RuntimeLoader {
                required property var modelData

                source: Qt.resolvedUrl("assets/rat.glb")
                scale: Qt.vector3d(modelData.scale, modelData.scale, modelData.scale)
                position: Qt.vector3d(modelData.position.x,
                                      modelData.position.y + modelData.wiggleOffset,
                                      modelData.position.z)
                rotation: modelData.rotation
            }
        }
    }

    RatPack {
        id: pack
        count: root.ratCount
        hullSource: Qt.resolvedUrl("assets/rat_hull.json")
        scaleMin: root.ratScaleMin
        scaleMax: root.ratScaleMax
        maxSpeed: root.ratMaxSpeed
        springStiffness: root.springStiffness
        springDamping: root.springDamping
        rotationStiffness: root.rotationStiffness
        wiggleAmplitude: root.wiggleAmplitude
        wiggleWavelength: root.wiggleWavelength
        cameraZ: root.cameraZ
        wallReferenceZ: root.shellZ
        wallX: root.wallX
    }
}
