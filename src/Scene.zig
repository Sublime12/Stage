const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("Node.zig").Node;
const NodeHandle = @import("Node.zig").NodeHandle;

pub const Scene = struct {
    const Self = @This();

    root: ?NodeHandle,

    /// Initilize the scene with an empty tree.
    pub fn init() Scene {
        return .{
            .root = null,
        };
    }

    /// Add a node to the root
    pub fn addRoot(self: *Self, node: NodeHandle) !void {
        self.root = node;
    }

    pub fn generateVertices(self: *Self, allocator: Allocator, vertices: *std.ArrayList(Vertex)) !void {
        if (self.root == null) return;
        try Node.generateVerticesRec(self.root.?.get(), allocator, vertices);
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

    pub fn init(position: [3]f32, color: [3]f32) Vertex {
        return .{
            .position = position,
            .color = color,
        };
    }
};
