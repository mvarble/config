#!/usr/bin/env python3
"""Extract collision data from a glTF binary (.glb): the OBB bounding the
mesh's convex hull (center + half extents), the bounding sphere radius,
and the 2D convex hull of the XY projection (kept for reference/debug).

Stdlib only. Usage: extract_hull.py input.glb output.json
"""

import json
import math
import struct
import sys


def read_glb(path):
    with open(path, "rb") as f:
        data = f.read()
    if data[:4] != b"glTF":
        raise SystemExit(f"{path}: not a glTF binary")
    json_len = struct.unpack_from("<I", data, 12)[0]
    if data[16:20] != b"JSON":
        raise SystemExit(f"{path}: first chunk is not JSON")
    gltf = json.loads(data[20:20 + json_len])
    off = 20 + json_len
    bin_len = struct.unpack_from("<I", data, off)[0]
    if data[off + 4:off + 8] != b"BIN\x00":
        raise SystemExit(f"{path}: second chunk is not BIN")
    return gltf, data[off + 8:off + 8 + bin_len]


def node_transform(gltf):
    """TRS of the first mesh node, as (translation, rotation_xyzw, scale)."""
    for node in gltf.get("nodes", []):
        if "mesh" in node:
            return (
                node.get("translation", [0.0, 0.0, 0.0]),
                node.get("rotation", [0.0, 0.0, 0.0, 1.0]),
                node.get("scale", [1.0, 1.0, 1.0]),
            )
    return ([0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 1.0], [1.0, 1.0, 1.0])


def quat_rotate(q, v):
    x, y, z, w = q
    # v + 2*cross(q.xyz, cross(q.xyz, v) + w*v)
    cx = y * v[2] - z * v[1] + w * v[0]
    cy = z * v[0] - x * v[2] + w * v[1]
    cz = x * v[1] - y * v[0] + w * v[2]
    return (
        v[0] + 2.0 * (y * cz - z * cy),
        v[1] + 2.0 * (z * cx - x * cz),
        v[2] + 2.0 * (x * cy - y * cx),
    )


def read_positions(gltf, binary):
    prim = gltf["meshes"][0]["primitives"][0]
    acc = gltf["accessors"][prim["attributes"]["POSITION"]]
    if acc["componentType"] != 5126:
        raise SystemExit("POSITION accessor is not float32")
    bv = gltf["bufferViews"][acc["bufferView"]]
    start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride", 12)
    pts = []
    for i in range(acc["count"]):
        pts.append(struct.unpack_from("<fff", binary, start + i * stride))
    return pts


def convex_hull_2d(points):
    """Monotone chain over the XY projection. Returns CCW hull points."""
    pts = sorted({(p[0], p[1]) for p in points})
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    gltf, binary = read_glb(sys.argv[1])
    t, r, s = node_transform(gltf)

    pts = []
    for p in read_positions(gltf, binary):
        scaled = (p[0] * s[0], p[1] * s[1], p[2] * s[2])
        rotated = quat_rotate(r, scaled)
        pts.append((rotated[0] + t[0], rotated[1] + t[1], rotated[2] + t[2]))

    mins = [min(p[k] for p in pts) for k in range(3)]
    maxs = [max(p[k] for p in pts) for k in range(3)]
    center = [(mins[k] + maxs[k]) / 2.0 for k in range(3)]
    half = [(maxs[k] - mins[k]) / 2.0 for k in range(3)]
    radius = max(
        math.dist(center, p) for p in pts
    )
    hull = convex_hull_2d(pts)

    out = {
        "obb": {"center": center, "halfExtents": half},
        "radius": radius,
        "hull2d": [[x, y] for x, y in hull],
        "vertexCount": len(pts),
    }
    with open(sys.argv[2], "w") as f:
        json.dump(out, f, indent=2)
    print(f"{sys.argv[2]}: {len(pts)} vertices, hull {len(hull)} points, "
          f"radius {radius:.4f}")


if __name__ == "__main__":
    main()
