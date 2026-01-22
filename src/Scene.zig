const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Scene = struct {
    const Self = @This();

    allocator: Allocator,
    root: Node,

    /// Initilize the scene with an empty tree.
    pub fn init(allocator: Allocator) Scene {
        return .{
            .allocator = allocator,
            .root = Node.initEmpty(),
        };
    }

    /// Recursively cleans up the entire tree.
    pub fn deinit(self: *Self) void {
        self.root.deinit(self.allocator);
    }

    /// Add a node to the root
    pub fn addNode(self: *Self, node: Node) !void {
        try self.root.addChild(self.allocator, node);
    }
};

pub const Node = struct {
    const Self = @This();

    children: std.ArrayList(Node),
    geometry: ?Geometry,

    pub fn init(geometry: Geometry) Node {
        return .{
            .children = std.ArrayList(Node).empty,
            .geometry = geometry,
        };
    }

    pub fn initEmpty() Node {
        return .{
            .children = std.ArrayList(Node).empty,
            .geometry = null,
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        for (self.children.items) |*child| {
            child.deinit(allocator);
        }
        self.children.deinit(allocator);

        if (self.geometry != null) {
            self.geometry.?.deinit(allocator);
        }
    }

    pub fn addChild(self: *Self, allocator: Allocator, node: Node) !void {
        try self.children.append(allocator, node);
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

    pub fn makeTriangle(allocator: Allocator) !Geometry {
        const triangle = Triangle.init(
            .{ .position = .{ 0.0, 1.0, 0.0 }, .color = .{ 0.0, 0.0, 1.0 } },
            .{ .position = .{ 1.0, 0.0, 0.0 }, .color = .{ 0.0, 1.0, 0.0 } },
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = .{ 1.0, 0.0, 0.0 } },
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
            .vertices = .{v1, v2, v3},
        };
    }
};

const Vertex = struct {
    position: [3]f32,
    color: [3]f32,

    pub fn init(position: [3]f32, color: [3]f32) Vertex {
        return .{
            .position = position,
            .color = color,
        };
    }
};
