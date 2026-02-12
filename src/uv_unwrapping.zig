const std = @import("std");

const scene = @import("scene.zig");
const math = @import("math.zig");

const Triangle = scene.Triangle;
const Triangle2d = scene.Triangle2d;
const Vertex = scene.Vertex;
const Vec3f = math.Vec3f;

pub fn flatten(t1: Triangle, t2: Triangle) Triangle2d {
    const adjancentSide = findAdjacentSide(t1, t2);
    _ = adjancentSide;
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
    // std.debug.assert(found);
    return result;
}

fn areVerticesEqlApprox(v1: Vec3f, v2: Vec3f) bool {
    if (!std.math.approxEqAbs(f32, v1[0], v2[0], 0.001)) return false;
    if (!std.math.approxEqAbs(f32, v1[1], v2[1], 0.001)) return false;
    if (!std.math.approxEqAbs(f32, v1[2], v2[2], 0.001)) return false;
    return true;
}

test "flattening smol triangle" {
    std.debug.print("Bonjour le monde\n", .{});
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
    _ = t1;
    _ = t2;

    // const res = flatten(t1, t2);

    // std.debug.print("flatten triangle: {any}\n", .{res});
}

test "find adjecent sides" {
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
    _ = d;
    const t1 = Triangle.init(a, b, c);
    const t2 = Triangle.init(b, c, a);

    const adjecents = findAdjacentSide(t1, t2);
    std.debug.print("{any}\n", .{adjecents});
}
