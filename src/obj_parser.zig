const std = @import("std");
const scene_pkg = @import("scene.zig");
const math = @import("math.zig");
const Geometry = scene_pkg.Geometry;
const Triangle = scene_pkg.Triangle;
const Vertex = scene_pkg.Vertex;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Reader = std.io.Reader;
const Vec3f = math.Vec3f;

const Face = [3][3]usize;
const X = 0;
const Y = 1;
const Z = 2;

pub fn obj_parse(reader_interface: *Reader, allocator: Allocator) !Geometry {
    var vertices: ArrayList(Vec3f) = ArrayList(Vec3f).empty;
    defer vertices.deinit(allocator);

    var faces: ArrayList(Face) = ArrayList(Face).empty;
    defer faces.deinit(allocator);

    while (try reader_interface.takeDelimiter('\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        const operation = it.next().?;

        if (std.mem.eql(u8, operation, "v")) {
            const x = try std.fmt.parseFloat(f32, it.next().?);
            const y = try std.fmt.parseFloat(f32, it.next().?);
            const z = try std.fmt.parseFloat(f32, it.next().?);

            try vertices.append(allocator, .{ x, y, z });
        } else if (std.mem.eql(u8, operation, "f")) {
            var face_values: [3][3]usize = undefined;
            var i: usize = 0;

            while (it.next()) |face_input| {
                if (i >= 3) break;
                var face = std.mem.splitScalar(u8, face_input, '/');
                const v = try std.fmt.parseInt(usize, face.next().?, 10);
                const vt = try std.fmt.parseInt(usize, face.next().?, 10);
                const vn = try std.fmt.parseInt(usize, face.next().?, 10);
                face_values[i] = .{ v, vt, vn };
                i += 1;
            }

            try faces.append(allocator, face_values);
        }
    }

    var geometry = Geometry.init();

    for (faces.items) |face| {
        const p1 = vertices.items[face[X][0] - 1];
        const p2 = vertices.items[face[Y][0] - 1];
        const p3 = vertices.items[face[Z][0] - 1];

        const v1 = Vertex.init(p1, .{ 1, 1, 1 }, .{ -1, -1 });
        const v2 = Vertex.init(p2, .{ 1, 1, 1 }, .{ -1, -1 });
        const v3 = Vertex.init(p3, .{ 1, 1, 1 }, .{ -1, -1 });

        const triangle = Triangle.init(v1, v2, v3);

        try geometry.shape.append(allocator, triangle);
    }

    return geometry;
}

test "expect obj_parse return a geometry with the correct coordinate" {
    const obj_text =
        \\# Blender 5.0.1
        \\# www.blender.org
        \\mtllib sphere.mtl
        \\o Icosphere
        \\v 0.000000 -1.000000 0.000000
        \\v 0.723607 -0.447220 0.525725
        \\v -0.276388 -0.447220 0.850649
        \\s 0
        \\f 1/1/1 2/2/1 3/3/1
    ;

    var reader = std.Io.Reader.fixed(obj_text);
    var triangleGeo = try obj_parse(&reader, std.testing.allocator);
    defer triangleGeo.deinit(std.testing.allocator);
    
    try std.testing.expectEqual(1, triangleGeo.shape.items.len);
    try std.testing.expectEqual(.{0.000000, -1.000000, 0.000000}, triangleGeo.shape.items[0].vertices[0].position);
    try std.testing.expectEqual(.{0.723607, -0.447220, 0.525725}, triangleGeo.shape.items[0].vertices[1].position);
    try std.testing.expectEqual(.{-0.276388, -0.447220, 0.850649}, triangleGeo.shape.items[0].vertices[2].position);
}
