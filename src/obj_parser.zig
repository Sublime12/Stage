const std = @import("std");
const scene_pkg = @import("scene.zig");
const math = @import("math.zig");
const Geometry = scene_pkg.Geometry;
const Triangle = scene_pkg.Triangle;
const Vertex = scene_pkg.Vertex;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Vec3f = math.Vec3f;

const Face = [3][3]usize;

pub const ObjParser = struct {

    pub fn parse(filepath: []const u8, allocator: Allocator) !Geometry {
        const file = try std.fs.cwd().openFile(filepath, .{ .mode = .read_only });
        defer file.close();

        var file_buffer: [256]u8 = undefined;
        var reader = file.reader(&file_buffer);
        const reader_interface = &reader.interface;
        
        var vertices: ArrayList(Vec3f) = ArrayList(Vec3f).empty;
        defer vertices.deinit(allocator);

        var faces: ArrayList(Face) = ArrayList(Face).empty;
        defer faces.deinit(allocator);

        while (try reader_interface.takeDelimiter('\n')) |line| {
            // std.debug.print("{s}\n", .{line});
             
            var it = std.mem.splitScalar(u8, line, ' ');
            const operation = it.next().?;

            if (std.mem.eql(u8, operation, "v")) {
                const x = try std.fmt.parseFloat(f32, it.next().?);
                const y = try std.fmt.parseFloat(f32, it.next().?);
                const z = try std.fmt.parseFloat(f32, it.next().?);

               try vertices.append(allocator, .{x, y, z});
            } else if (std.mem.eql(u8, operation, "f")) {
                var face_values: [3][3]usize = undefined;
                var i: usize = 0;

                while (it.next()) |face_input| {
                    var face = std.mem.splitScalar(u8, face_input, '/');
                    const v = try std.fmt.parseInt(usize, face.next().?, 10);
                    const vt = try std.fmt.parseInt(usize, face.next().?, 10);
                    const vn = try std.fmt.parseInt(usize, face.next().?, 10);
                    face_values[i] = .{v, vt, vn};
                    i += 1;
                }

                try faces.append(allocator, face_values);
            }
        }
        
        var geometry = Geometry.init();

        for (faces.items) |face| {
            // std.debug.print("{any}\n", .{vertices.items[face[0][0] - 1]});
            const p1 = vertices.items[face[0][0] - 1];
            const p2 = vertices.items[face[1][0] - 1]; 
            const p3 = vertices.items[face[2][0] - 1];

            const v1 = Vertex.init(p1, .{1, 1, 1}, .{-1, -1});
            const v2 = Vertex.init(p2, .{1, 1, 1}, .{-1, -1});
            const v3 = Vertex.init(p3, .{1, 1, 1}, .{-1, -1});
            
            const triangle = Triangle.init(v1, v2, v3);

            try geometry.shape.append(allocator, triangle);
        }

        // std.debug.print("vertices size: {}\n", .{verteces.items.len});
        // std.debug.print("{any}\n\n", .{verteces.items});
        //
        // std.debug.print("faces size: {}\n", .{faces.items.len});
        // std.debug.print("{any}\n", .{faces.items});

        return geometry;
    }
};

test "_" {
    _ = try ObjParser.parse("./assets/sphere.obj", std.testing.allocator);
    unreachable;
}
