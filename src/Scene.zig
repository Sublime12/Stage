const std = @import("std");

const Allocator = std.mem.Allocator;

const Scene = struct {
    tree: GraphicTree,

    pub fn init(alloc: Allocator) Scene {
        const tree = GraphicTree.init(alloc);
        return .{
            .tree = tree,
        };
    }

    pub fn addNode(self: @This(), node: Node) void {
        self.tree.addNode(node);
    }
};

const GraphicTree = struct {
    root: Node,
    pub fn addNode(self: @This(), node: Node) void {
        self.root.addNode(node);
    }
};

const Node = struct {
    const Nodes = std.ArrayList(Node);

    children: std.ArrayList(Node),
    geometry: Geometry,

    pub fn addNode(self: @This(), node: Node, gpa: Allocator) !void {
        try self.children.append(gpa, node);
    }

    pub fn init(geometry: Geometry) Node {
        const children = Nodes.empty;
        return .{
            .children = children,
            .geometry = geometry,
        };
    }
};

const Geometry = struct {
    const Triangles = std.ArrayList(Triangle);

    form: Triangles,

    pub fn init() Geometry {
        const form = Triangles.empty;

        return .{
            .form = form,
        };
    }

    pub fn makeTriangle() Geometry {}
};

const Triangle = struct {};
