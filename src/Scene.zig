const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Scene = struct {
    const Self = @This();

    tree: GraphicTree,

    pub fn init() Scene {
        const tree = GraphicTree.init();
        return .{
            .tree = tree,
        };
    }

    pub fn addNode(self: *Self, node: Node, gpa: Allocator) !void {
        try self.tree.addNode(node, gpa);
    }

    pub fn deinit(self: *Self, gpa: Allocator) void {
        self.tree.deinit(gpa);
    }
};

const GraphicTree = struct {
    const Self = @This();

    root: Node,

    pub fn init() GraphicTree {
        return .{
            .root = Node.empty(),
        };
    }

    pub fn addNode(self: *Self, node: Node, gpa: Allocator) !void {
        try self.root.addNode(node, gpa);
    }

    pub fn deinit(self: *Self, gpa: Allocator) void {
        self.root.deinit(gpa);
    } 
};

pub const Node = struct {
    const Self = @This();

    const Nodes = std.ArrayList(Node);

    children: std.ArrayList(Node),
    geometry: ?Geometry,

    pub fn init(geometry: Geometry) Node {
        const children = Nodes.empty;
        return .{
            .children = children,
            .geometry = geometry,
        };
    }

    pub fn deinit(self: *Self, gpa: Allocator) void {
        for (self.children.items) |*child| {
            child.deinit(gpa);
        }
        
        self.children.deinit(gpa);

        if (self.geometry != null) {
            self.geometry.?.deinit(gpa);
        }
    }

    pub fn empty() Node {
        return .{
            .children = Nodes.empty,
            .geometry = null,
        };
    }

    pub fn addNode(self: *Self, node: Node, gpa: Allocator) !void {
        try self.children.append(gpa, node);
    }
};

pub const Geometry = struct {
    const Self = @This();

    form: std.ArrayList(Triangle),

    pub fn init() Geometry {
        const form = std.ArrayList(Triangle).empty;

        return .{
            .form = form,
        };
    }

    pub fn deinit(self: *Self, gpa: Allocator) void {
        self.form.deinit(gpa);
    }

    pub fn makeTriangle(gpa: Allocator) !Geometry {
        const vertices: [3]Vertex = .{
            .{ .position = .{ .x = 0.0, .y = 1.0, .z = 0.0 }, .color = .{ .r = 0.0, .g = 0.0, .b = 1.0 } },
            .{ .position = .{ .x = 1.0, .y = 0.0, .z = 0.0 }, .color = .{ .r = 0.0, .g = 1.0, .b = 0.0 } },
            .{ .position = .{ .x = 0.0, .y = 0.0, .z = 0.0 }, .color = .{ .r = 1.0, .g = 0.0, .b = 0.0 } },
        };
        const triangle = Triangle.init(vertices);
        
        var geometry = Geometry.init();
        try geometry.form.append(gpa, triangle);

        return geometry;
    }
};

const Triangle = struct {
    vertices: [3]Vertex,

    pub fn init(vertices: [3]Vertex) Triangle {
        return .{
            .vertices = vertices,
        };
    }
};

const Vertex = struct {
    position: Position,
    color: Color,

    pub fn init(position: Position, color: Color) Vertex {
        return .{
            .position = position,
            .color = color,
        };
    }
};

const Position = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Position {
        return .{
            .x = x,
            .y = y,
            .z = z, 
        };
    }
};

const Color = struct {
    r: f32,
    g: f32,
    b: f32,

    pub fn init(r: f32, g: f32, b: f32) Color {
        return .{
            .r = r,
            .g = g,
            .b = b, 
        };
    }
};
