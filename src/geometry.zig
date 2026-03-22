const std = @import("std");
const math = @import("math.zig");

const Allocator = std.mem.Allocator;
const Vec3f = math.Vec3f;
const Vec2f = math.Vec2f;

pub const Geometry = struct {
    const Self = @This();

    /// A list of triangles that represent the 3D shape.
    shape: std.ArrayList(Triangle),

    pub fn init() Geometry {
        return .{
            .shape = std.ArrayList(Triangle).empty,
        };
    }

    pub fn setBaseColor(self: *Self, baseColor: Vec3f) void {
        for (self.shape.items) |*triangle| {
            for (0..triangle.vertices.len) |i| {
                triangle.vertices[i].color = baseColor;
            }
        }
    }

    pub fn clone(self: *const Self, allocator: Allocator) !Geometry {
        return .{
            .shape = try self.shape.clone(allocator),
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.shape.deinit(allocator);
    }

    pub fn makeTriangle(allocator: Allocator, tx: f32, ty: f32, tz: f32) !Geometry {
        const triangle = Triangle.init(
            .{ .position = .{ tx + 0.0, ty + 0.5, tz + 0.0 }, .color = .{ 0.0, 0.0, 0.5 }, .textCoord = .{ 0, 0 } },
            .{ .position = .{ tx + 0.5, ty + 0.0, tz + 0.0 }, .color = .{ 0.0, 0.5, 0.0 }, .textCoord = .{ 0, 0 } },
            .{ .position = .{ tx + 0.0, ty + 0.0, tz + 0.0 }, .color = .{ 0.5, 0.0, 0.0 }, .textCoord = .{ 0, 0 } },
        );

        var geometry = Geometry.init();
        try geometry.shape.append(allocator, triangle);

        return geometry;
    }

    pub fn makeCube(allocator: Allocator) !Geometry {
        // Face 1
        const black = .{ 0.0, 0.0, 0.0 };
        const triangle1 = Triangle.init(
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = black, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = black, .textCoord = .{ 0, 0 } },
        );

        const triangle2 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = black, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = black, .textCoord = .{ 0, 1 } },
        );

        // Face 2
        const triangle3 = Triangle.init(
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = black, .textCoord = .{ 0, 0 } },
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
        );

        const triangle4 = Triangle.init(
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = black, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
        );

        // Face 3
        const triangle5 = Triangle.init(
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = black, .textCoord = .{ 0, 0 } },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = black, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
        );

        const triangle6 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.5 }, .color = black, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = black, .textCoord = .{ 1, 0 } },
        );

        // Face 4
        const triangle7 = Triangle.init(
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = black, .textCoord = .{ 0, 0 } },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
        );

        const triangle8 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.5 }, .color = black, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
        );

        // Face 4
        const triangle9 = Triangle.init(
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = black, .textCoord = .{ 0, 0 } },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
        );

        const triangle10 = Triangle.init(
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = black, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
        );

        // Face 6
        const triangle11 = Triangle.init(
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = black, .textCoord = .{ 0, 0 } },
        );

        const triangle12 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.5 }, .color = black, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = black, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = black, .textCoord = .{ 0, 1 } },
        );

        var geometry = Geometry.init();

        try geometry.shape.append(allocator, triangle9);
        try geometry.shape.append(allocator, triangle1);
        try geometry.shape.append(allocator, triangle2);
        try geometry.shape.append(allocator, triangle3);
        try geometry.shape.append(allocator, triangle4);
        try geometry.shape.append(allocator, triangle5);
        try geometry.shape.append(allocator, triangle6);
        try geometry.shape.append(allocator, triangle7);
        try geometry.shape.append(allocator, triangle8);
        try geometry.shape.append(allocator, triangle10);
        try geometry.shape.append(allocator, triangle11);
        try geometry.shape.append(allocator, triangle12);

        return geometry;
    }
};

pub const Triangle = struct {
    vertices: [3]Vertex,

    pub fn init(v1: Vertex, v2: Vertex, v3: Vertex) Triangle {
        return .{
            .vertices = .{ v1, v2, v3 },
        };
    }
};

pub const Triangle2d = struct {
    vertices: [3]Vec2f,
    from_3d: Triangle,

    pub fn init(v1: Vec2f, v2: Vec2f, v3: Vec2f, from3d: Triangle) Triangle2d {
        return .{
            .vertices = .{ v1, v2, v3 },
            .from_3d = from3d,
        };
    }
};

pub const Vertex = struct {
    position: [3]f32,
    color: [3]f32,
    normal: [3]f32 = .{ 0, 0, -1 },
    textCoord: [2]f32,
    textureId: i32 = -1,

    pub fn init(position: [3]f32, color: [3]f32, textCoord: [2]f32) Vertex {
        return .{
            .position = position,
            .color = color,
            .textCoord = textCoord,
            .normal = .{ 0, 0, 1 },
            .textureId = -1,
        };
    }
};
