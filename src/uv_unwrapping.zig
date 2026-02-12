const std = @import("std");

const scene = @import("scene.zig");

const Triangle = scene.Triangle;
const Triangle2d = scene.Triangle2d;
const Vertex = scene.Vertex;

pub fn flatten(t1: Triangle, t2: Triangle) Triangle2d {
    _ = t1;
    _ = t2;
    unreachable;
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

    _ = flatten(t1, t2);
}
