const std = @import("std");

const scene = @import("scene.zig");
const math = @import("math.zig");

const Triangle = scene.Triangle;
const Triangle2d = scene.Triangle2d;
const Vertex = scene.Vertex;
const Vec3f = math.Vec3f;

pub fn flatten(t1: Triangle, t2: Triangle) Triangle2d {
    const adjancentSide = findAdjacentSide(t1, t2);
    const b = adjancentSide[0];
    const c = adjancentSide[1];
    const d = extractDifferentPoint(t2, c, b);
    const a = extractDifferentPoint(t1, c, b);
    _ = d;
    _ = a;
    // std.debug.print("d: {any}\n", .{d});
    // std.debug.print("a: {any}\n", .{a});
    unreachable;
}

fn extractDifferentPoint(t: Triangle, c: Vertex, b: Vertex) Vertex {
    return if (!areVerticesEqlApprox(t.vertices[0].position, b.position) and
        !areVerticesEqlApprox(t.vertices[0].position, c.position))
        t.vertices[0]
    else if (!areVerticesEqlApprox(t.vertices[1].position, b.position) and
        !areVerticesEqlApprox(t.vertices[1].position, c.position))
        t.vertices[1]
    else if (!areVerticesEqlApprox(t.vertices[2].position, b.position) and
        !areVerticesEqlApprox(t.vertices[2].position, c.position))
        t.vertices[2]
    else
        unreachable;
}

fn findAdjacentSide(t1: Triangle, t2: Triangle) [2]Vertex {
    var result: [2]Vertex = undefined;
    const emptyVertex = Vertex.init(
        .{ 0, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    @memset(&result, emptyVertex);
    var i: usize = 0;
    for (t1.vertices) |v1| {
        for (t2.vertices) |v2| {
            if (areVerticesEqlApprox(v1.position, v2.position) and i < 2) {
                result[i] = v1;
                i += 1;
                break;
            }
        }
    }
    std.debug.assert(i == 2);
    return result;
}

fn areVerticesEqlApprox(v1: Vec3f, v2: Vec3f) bool {
    if (!std.math.approxEqAbs(f32, v1[0], v2[0], 0.001)) return false;
    if (!std.math.approxEqAbs(f32, v1[1], v2[1], 0.001)) return false;
    if (!std.math.approxEqAbs(f32, v1[2], v2[2], 0.001)) return false;
    return true;
}

fn makeTwoTriangle() [2]Triangle {
    const a = Vertex.init(
        .{ 0, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const b = Vertex.init(
        .{ 1, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const c = Vertex.init(
        .{ 0, 0, 1 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const d = Vertex.init(
        .{ 2, 1, 1 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const t1 = Triangle.init(a, b, c);
    const t2 = Triangle.init(b, c, d);

    return .{ t1, t2 };
}

test "find adjacents for t2 triangles" {
    const triangles = makeTwoTriangle();
    const t1 = triangles[0];
    const t2 = triangles[1];

    const adjacents = findAdjacentSide(t1, t2);
    try std.testing.expectEqual(adjacents[0], t2.vertices[0]);
    try std.testing.expectEqual(adjacents[1], t2.vertices[1]);
}

test "find different point in triangle" {
    const a = Vertex.init(
        .{ 0, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const b = Vertex.init(
        .{ 1, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const c = Vertex.init(
        .{ 0, 0, 1 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const d = Vertex.init(
        .{ 2, 1, 1 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const t1 = Triangle.init(a, b, c);
    const t2 = Triangle.init(b, c, d);
    const expected_d = extractDifferentPoint(t2, c, b);
    const expected_a = extractDifferentPoint(t1, c, b);

    try std.testing.expectEqual(expected_d, d);
    try std.testing.expectEqual(expected_a, a);
}
