const std = @import("std");
const Allocator = std.mem.Allocator;

const Geometry = @import("scene.zig").Geometry;
const Vertex = @import("scene.zig").Vertex;
const math = @import("transform.zig");
const Transform = math.Transform;

pub const NodeHandle = struct {
    pool: *NodePool,
    index: usize,

    /// return the pointer to the element in the array pool
    /// The user must not stored it for long because it can be invalided
    /// on array list resizing
    pub fn get(self: *NodeHandle) *Node {
        return &self.pool.nodes.items[self.index];
    }
};

pub const NodePool = struct {
    const Self = @This();

    allocator: Allocator,
    nodes: std.ArrayList(Node),

    pub fn init(allocator: Allocator) NodePool {
        return .{
            .allocator = allocator,
            .nodes = .empty,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.nodes.items) |*node| {
            node.deinit(self.allocator);
        }
        self.nodes.deinit(self.allocator);
    }

    pub fn create(self: *NodePool, node: Node) !NodeHandle {
        try self.nodes.append(self.allocator, node);
        return .{
            .pool = self,
            .index = self.nodes.items.len - 1,
        };
    }
};

pub const Node = struct {
    const Self = @This();

    children: std.ArrayList(NodeHandle),
    geometry: ?Geometry,
    transform: Transform,

    pub fn init(geometry: Geometry) Node {
        return .{
            .children = std.ArrayList(NodeHandle).empty,
            .geometry = geometry,
            .transform = comptime Transform.init(),
        };
    }

    pub fn initEmpty() Node {
        return .{
            .children = std.ArrayList(NodeHandle).empty,
            .geometry = null,
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        // Child handles are owned by the caller
        // You must not free the handles themselves
        // but just free the arraylist containing it
        self.children.deinit(allocator);
        if (self.geometry) |*geo| {
            geo.deinit(allocator);
        }
    }

    pub fn addChild(self: *Self, allocator: Allocator, node: NodeHandle) Allocator.Error!void {
        try self.children.append(allocator, node);
    }

    pub fn generateVerticesRec(
        node: *Node,
        allocator: Allocator,
        vertices: *std.ArrayList(Vertex),
        transforms: *std.ArrayList(Transform),
    ) !void {
        const top_transform = transforms.getLast();
        const current_transform = Transform.from(&top_transform, &node.transform);
        try transforms.append(allocator, current_transform);
        defer _ = transforms.pop();

        // std.debug.print("children len : {}\n", .{node.children.items.len});
        if (node.geometry) |geometry| {
            // std.debug.print("triangles: {}\n", .{geometry.shape.items.len});
            for (geometry.shape.items) |triangle| {
                // try vertices.appendSlice(allocator, &triangle.vertices);

                for (triangle.vertices) |vertex| {
                    const newVertex = current_transform.transformVertex(&vertex);
                    try vertices.append(allocator, newVertex);
                }
            }
        }

        for (node.children.items) |*child| {
            try generateVerticesRec(child.get(), allocator, vertices, transforms);
        }
    }
};
