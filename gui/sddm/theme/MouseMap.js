// Maps a 2D mouse position to a 3D target point on a fixed-radius shell
// around the camera. The camera is fixed at (0, 0, camZ) looking down -Z,
// so the ray through a pixel only needs the field of view and aspect.

.pragma library

function screenToTarget(mouseX, mouseY, viewWidth, viewHeight, camZ, fovDeg, shellDistance) {
    var fov = fovDeg * Math.PI / 180.0
    var halfH = Math.tan(fov / 2.0)
    var halfW = halfH * (viewWidth / viewHeight)

    var nx = (mouseX / viewWidth) * 2.0 - 1.0
    var ny = 1.0 - (mouseY / viewHeight) * 2.0

    var dx = nx * halfW
    var dy = ny * halfH
    var dz = -1.0
    var len = Math.sqrt(dx * dx + dy * dy + dz * dz)

    return {
        "x": (dx / len) * shellDistance,
        "y": (dy / len) * shellDistance,
        "z": camZ + (dz / len) * shellDistance
    }
}

// World-space X of a vertical screen-space line (given in NDC, -1..1)
// at a given world depth. Matches the ray convention of screenToTarget.
function ndcToWorldX(ndcX, worldZ, camZ, fovDeg, aspect) {
    var halfW = Math.tan(fovDeg * Math.PI / 360.0) * aspect
    return (camZ - worldZ) * ndcX * halfW
}
