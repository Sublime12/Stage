const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const NodeHandle = @import("node.zig").NodeHandle;
const Transform = @import("transform.zig").Transform;
const light_pkg = @import("light.zig");
const Light = light_pkg.Light;
const LightHandle = light_pkg.LightHandle;

pub const Scene = struct {
    const Self = @This();
    pub const MaxLights = 5;

    root: ?NodeHandle,
    // light: ?Light,
    lights: std.ArrayList(LightHandle),
    allocator: Allocator,

    /// Initilize the scene with an empty tree.
    pub fn init(allocator: Allocator) !Scene {
        return .{
            .root = null,
            .allocator = allocator,
            .lights = try std.ArrayList(LightHandle).initCapacity(allocator, MaxLights),
            // .light = null,
        };
    }

    pub fn deinit(self: *Self) void {
        self.lights.deinit(self.allocator);
    }

    pub fn addLight(self: *Self, light: LightHandle) void {
        // self.light = light.*;
        self.lights.appendAssumeCapacity(light);
    }

    // Add a node to the root
    pub fn addRoot(self: *Self, node: NodeHandle) !void {
        self.root = node;
    }

    pub fn generateVertices(
        self: *Self,
        allocator: Allocator,
        vertices: *std.ArrayList(Vertex),
    ) !void {
        if (self.root == null) return;

        var transforms = std.ArrayList(Transform).empty;
        defer transforms.deinit(allocator);
        try transforms.append(allocator, Transform.init());
        try Node.updateWorldTransform(
            self.root.?.get(),
            allocator,
            &transforms,
        );
        try Node.generateVerticesRec(
            self.root.?.get(),
            allocator,
            vertices,
        );

        std.debug.assert(transforms.items.len == 1);
    }
};

pub const Geometry = struct {
    const Self = @This();

    /// A list of triangles that represent the 3D shape.
    shape: std.ArrayList(Triangle),

    pub fn init() Geometry {
        return .{
            .shape = std.ArrayList(Triangle).empty,
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.shape.deinit(allocator);
    }

    pub fn makeTriangle(allocator: Allocator, tx: f32, ty: f32, tz: f32) !Geometry {
        const triangle = Triangle.init(
            .{ .position = .{ tx + 0.0, ty + 0.5, tz + 0.0 }, .color = .{ 0.0, 0.0, 0.5 } },
            .{ .position = .{ tx + 0.5, ty + 0.0, tz + 0.0 }, .color = .{ 0.0, 0.5, 0.0 } },
            .{ .position = .{ tx + 0.0, ty + 0.0, tz + 0.0 }, .color = .{ 0.5, 0.0, 0.0 } },
        );

        var geometry = Geometry.init();
        try geometry.shape.append(allocator, triangle);

        return geometry;
    }

    pub fn makeCube(allocator: Allocator) !Geometry {
        // Face 1
        const blue = .{ 0.0, 0.0, 1.0 };
        const triangle1 = Triangle.init(
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = blue },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = blue },
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = blue },
        );

        const triangle2 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = blue },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = blue },

            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = blue },
        );

        // Face 2
        const red = .{ 1.0, 0.0, 0.0 };

        const triangle3 = Triangle.init(
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = red },

            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = red },

            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = red },
        );

        const triangle4 = Triangle.init(
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = red },
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = red },

            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = red },
        );

        // Face 3
        const gray = .{ 0.5, 0.5, 0.5 };
        const triangle5 = Triangle.init(
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = gray },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = gray },
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = gray },
        );

        const triangle6 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.5 }, .color = gray },
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = gray },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = gray },
        );

        // Face 4
        const yellow = .{ 1.0, 1.0, 0.0 };

        const triangle7 = Triangle.init(
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = yellow },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = yellow },

            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = yellow },
        );

        const triangle8 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.5 }, .color = yellow },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = yellow },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = yellow },
        );

        // Face 4
        const skyblue = .{ 0.0, 1.0, 1.0 };

        const triangle9 = Triangle.init(
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = skyblue },

            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = skyblue },

            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = skyblue },
        );

        const triangle10 = Triangle.init(
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = skyblue },
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = skyblue },

            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = skyblue },
        );

        // Face 6
        const white = .{ 1.0, 1.0, 1.0 };

        const triangle11 = Triangle.init(
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = white },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = white },

            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = white },
        );

        const triangle12 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.5 }, .color = white },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = white },

            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = white },
        );

        var geometry = Geometry.init();
        try geometry.shape.append(allocator, triangle1);
        try geometry.shape.append(allocator, triangle2);
        try geometry.shape.append(allocator, triangle3);
        try geometry.shape.append(allocator, triangle4);
        try geometry.shape.append(allocator, triangle5);
        try geometry.shape.append(allocator, triangle6);
        try geometry.shape.append(allocator, triangle7);
        try geometry.shape.append(allocator, triangle8);
        try geometry.shape.append(allocator, triangle9);
        try geometry.shape.append(allocator, triangle10);
        try geometry.shape.append(allocator, triangle11);
        try geometry.shape.append(allocator, triangle12);

        return geometry;
    }
};

const Triangle = struct {
    vertices: [3]Vertex,

    pub fn init(v1: Vertex, v2: Vertex, v3: Vertex) Triangle {
        return .{
            .vertices = .{ v1, v2, v3 },
        };
    }
};

pub const Vertex = struct {
    position: [3]f32,
    color: [3]f32,
    // TODO initialize correct normal for all vertices
    normal: [3]f32 = .{ 0, 0, -1 },

    pub fn init(position: [3]f32, color: [3]f32) Vertex {
        return .{
            .position = position,
            .color = color,
            .normal = .{ 0, 0, 1 },
        };
    }
};
