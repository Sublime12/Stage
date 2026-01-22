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
        std.debug.print("IN DEINIT SCENE\n", .{});
        self.root.deinit(self.allocator);
    }

    /// Add a node to the root
    pub fn addNode(self: *Self, node: *const Node) !void {
        var vertices = std.ArrayList(Vertex).empty;
        try generateVertices(self, self.allocator, &vertices);

        std.debug.print("\n\nnb vertex: {}\n", .{vertices.items.len});
        for (vertices.items) |vertex| {
            std.debug.print("v: {any}\n", .{vertex});
        }

        try self.root.addChild(self.allocator, node);
    }

    pub fn generateVertices(self: *Self, allocator: Allocator, vertices: *std.ArrayList(Vertex)) !void {
        try generateVerticesRec(&self.root, allocator, vertices);
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

    pub fn addChild(self: *Self, allocator: Allocator, node: *const Node) !void {
        try self.children.append(allocator, node.*);
    }
};

fn generateVerticesRec(node: *Node, allocator: Allocator, vertices: *std.ArrayList(Vertex)) !void {
    std.debug.print("children len : {}\n", .{node.children.items.len});
    if (node.geometry) |geometry| {
        std.debug.print("triangles: {}\n", .{geometry.shape.items.len});
        for (geometry.shape.items) |triangle| {
            try vertices.appendSlice(allocator, &triangle.vertices);
        }
    }

    for (node.children.items) |*child| {
        try generateVerticesRec(child, allocator, vertices);
    }
}

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
