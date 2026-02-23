const std = @import("std");

const scene = @import("scene.zig");
const math = @import("math.zig");
const link_list = @import("link_list.zig");
const obj_parser_pkg = @import("obj_parser.zig");

const Allocator = std.mem.Allocator;

const Triangle = scene.Triangle;
const Triangle2d = scene.Triangle2d;
const Vertex = scene.Vertex;
const Geometry = scene.Geometry;
const Vec3f = math.Vec3f;
const Vec2f = math.Vec2f;
const DoublyLinkedList = link_list.DoublyLinkedList;
const obj_parse = obj_parser_pkg.obj_parse;

const X = 0;
const Y = 1;
const Z = 2;

const assert = std.debug.assert;

const Node3d = struct {
    triangle: TriangleNode,
    neighbors: std.ArrayList(GeometryGraph3d.NodeHandle),
};

pub const GeometryGraph3d = struct {
    const NodeHandle = struct {
        nodes: *std.ArrayList(Node3d),
        index: usize,

        pub fn get(self: NodeHandle) *Node3d {
            return &self.nodes.items[self.index];
        }
    };

    const Self = @This();

    nodes: std.ArrayList(Node3d),
    geometry: *const Geometry,

    pub fn init(geometry: *const Geometry) Self {
        return .{
            .nodes = .empty,
            .geometry = geometry,
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        for (self.nodes.items) |*node| {
            node.neighbors.deinit(allocator);
        }
        self.nodes.deinit(allocator);
    }

    pub fn generate(self: *Self, allocator: Allocator) !void {
        // const triangles = self.geometry.shape;

        for (0..self.geometry.shape.items.len) |i| {
            const node: Node3d = .{ .triangle = .{ .index = i, .pool = &self.geometry.shape }, .neighbors = .empty };
            try self.nodes.append(allocator, node);
        }

        for (self.nodes.items, 0..) |*n1, i| {
            for (self.nodes.items, 0..) |n2, j| {
                if (i == j) continue;

                if (findAdjacentSide(n1.triangle.get().*, n2.triangle.get().*)) |_| {
                    try n1.neighbors.append(allocator, .{
                        .nodes = &self.nodes,
                        .index = j,
                    });
                }
            }
        }
    }

    pub fn uvUnwrap(self: *Self, allocator: Allocator) !GeometryGraph2d {
        var nextNodes = DoublyLinkedList(NodeHandle).init(allocator);
        defer nextNodes.deinit();
        var visited = std.AutoHashMap(NodeHandle, void).init(allocator);
        defer visited.deinit();

        var flattened = std.AutoArrayHashMap(NodeHandle, Triangle2d).init(allocator);
        defer flattened.deinit();

        assert(self.nodes.items.len >= 2);

        const firstHandle: NodeHandle = .{
            .nodes = &self.nodes,
            .index = 0,
        };

        try visited.putNoClobber(firstHandle, {});
        try nextNodes.append(firstHandle);

        const first = self.nodes.items[0].triangle;
        const first_2d = Triangle2d.init(
            .{ first.get().vertices[0].position[0], first.get().vertices[0].position[2] },
            .{ first.get().vertices[1].position[0], first.get().vertices[1].position[2] },
            .{ first.get().vertices[2].position[0], first.get().vertices[2].position[2] },
            first.get().*,
        );

        try flattened.putNoClobber(.{
            .nodes = &self.nodes,
            .index = 0,
        }, first_2d);

        while (!nextNodes.empty()) {
            const tpop = nextNodes.popFirst() orelse unreachable;
            for (tpop.get().neighbors.items) |neighbor| {
                if (visited.contains(neighbor)) continue;

                const t1_2d = flattened.get(tpop).?;
                const flattenedNeighbor = flatten(
                    tpop.get().triangle.get().*,
                    neighbor.get().triangle.get().*,
                    t1_2d,
                );

                try flattened.putNoClobber(neighbor, flattenedNeighbor);
                try visited.putNoClobber(neighbor, {});
                try nextNodes.append(neighbor);
            }
        }

        var graph = GeometryGraph2d.initEmpty(self.geometry);

        var it = flattened.iterator();
        while (it.next()) |entry| {
            const node3d = entry.key_ptr;
            const flatten2d = entry.value_ptr;

            const node2d = Node2d.init(
                flatten2d.*,
                node3d.get().triangle,
            );
            try graph.nodes.append(allocator, node2d);
        }

        graph.normalize();
        graph.update3dUvs();

        return graph;
    }

    pub fn format(
        self: Self,
        writer: anytype,
    ) !void {
        try writer.writeAll("graph GeometryGraph {\n");
        try writer.writeAll("  node [shape=box];\n");

        for (self.nodes.items, 0..) |node, i| {
            const v = node.triangle.vertices;
            try writer.print(
                \\  n{d} [label=\"ID: {d}\\nV0: ({d:.2}, {d:.2}, {d:.2})\\nV1: 
                \\ ({d:.2}, {d:.2}, {d:.2})\\nV2: ({d:.2}, {d:.2}, {d:.2})\"];\n"
            ,
                .{
                    i,                i,
                    v[0].position[0], v[0].position[1],
                    v[0].position[2], v[1].position[0],
                    v[1].position[1], v[1].position[2],
                    v[2].position[0], v[2].position[1],
                    v[2].position[2],
                },
            );

            for (node.neighbors.items) |neighbor| {
                for (self.nodes.items, 0..) |target, j| {
                    if (i < j and std.meta.eql(neighbor.triangle, target.triangle)) {
                        try writer.print("  n{d} -- n{d};\n", .{ i, j });
                        break;
                    }
                }
            }
        }

        try writer.writeAll("}\n");
    }
};

const TriangleNode = struct {
    const Self = @This();
    index: usize,
    pool: *const std.ArrayList(Triangle),

    pub fn get(self: *const Self) *Triangle {
        return &self.pool.items[self.index];
    }
};

const Node2d = struct {
    // triangle: scene.Triangle,
    triangle: TriangleNode,
    triangle2d: Triangle2d,
    neighbors: std.ArrayList(Node2d),

    pub fn init(triangle2d: Triangle2d, triangleNode: TriangleNode) Node2d {
        return .{
            .triangle = triangleNode,
            .triangle2d = triangle2d,
            .neighbors = .empty,
        };
    }
};

pub const GeometryGraph2d = struct {
    const Self = @This();

    nodes: std.ArrayList(Node2d),
    geometry: *const Geometry,

    pub fn initEmpty(geometry: *const Geometry) Self {
        return .{
            .nodes = .empty,
            .geometry = geometry,
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.nodes.deinit(allocator);
    }

    pub fn update3dUvs(self: *Self) void {
        for (self.nodes.items) |node2d| {
            for (0..node2d.triangle2d.vertices.len) |i| {
                const vertex = node2d.triangle2d.vertices[i];
                node2d.triangle.get().vertices[i].textCoord[0] = vertex[0];
                node2d.triangle.get().vertices[i].textCoord[1] = vertex[1];
            }
        }
    }

    pub fn normalize(self: *Self) void {
        var maxX: f32 = -std.math.inf(f32);
        var minX: f32 = std.math.inf(f32);
        var maxY: f32 = -std.math.inf(f32);
        var minY: f32 = std.math.inf(f32);

        for (self.nodes.items) |node| {
            const triangle = node.triangle2d;
            for (triangle.vertices) |vertex| {
                if (vertex[X] > maxX) maxX = vertex[X];
                if (vertex[X] < minX) minX = vertex[X];
                if (vertex[Y] > maxY) maxY = vertex[Y];
                if (vertex[Y] < minY) minY = vertex[Y];
            }
        }

        for (self.nodes.items) |*node| {
            for (0..node.triangle2d.vertices.len) |i| {
                const vertex = node.triangle2d.vertices[i];
                node.triangle2d.vertices[i][X] = (vertex[X] - minX) / (maxX - minX);
                node.triangle2d.vertices[i][Y] = (vertex[Y] - minY) / (maxY - minY);
            }
        }
    }

    pub fn print(self: *const Self) void {
        for (self.nodes.items) |node| {
            const vertices = node.triangle2d.vertices;
            std.debug.print("(({}, {}), ({}, {}), ({}, {})),\n", .{
                vertices[0][0], vertices[0][1],
                vertices[1][0], vertices[1][1],
                vertices[2][0], vertices[2][1],
            });
        }
    }
};

pub fn flatten(t1: Triangle, t2: Triangle, t1_2d: Triangle2d) Triangle2d {
    const adjancentSide = findAdjacentSide(t1, t2);
    const B = adjancentSide.?[0];
    const C = adjancentSide.?[1];
    const D = extractDifferentPoint(t2, C, B);
    var vbc3d: Vec3f = undefined;
    var vbd3d: Vec3f = undefined;
    math.substractVec3(&vbc3d, &C.position, &B.position);
    math.substractVec3(&vbd3d, &D.position, &B.position);
    var vcd3d: Vec3f = undefined;
    math.substractVec3(&vcd3d, &D.position, &C.position);
    const d2 = math.lengthVec3(&vcd3d);
    const d1 = math.lengthVec3(&vbd3d);
    var b_opt: ?Vec2f = null;
    if (areVerticesEqlApprox(B.position, t1_2d.from_3d.vertices[0].position)) {
        b_opt = t1_2d.vertices[0];
    } else if (areVerticesEqlApprox(B.position, t1_2d.from_3d.vertices[1].position)) {
        b_opt = t1_2d.vertices[1];
    } else if (areVerticesEqlApprox(B.position, t1_2d.from_3d.vertices[2].position)) {
        b_opt = t1_2d.vertices[2];
    }
    assert(b_opt != null);
    const b = b_opt.?;

    var c_opt: ?Vec2f = null;
    if (areVerticesEqlApprox(C.position, t1_2d.from_3d.vertices[0].position)) {
        c_opt = t1_2d.vertices[0];
    } else if (areVerticesEqlApprox(C.position, t1_2d.from_3d.vertices[1].position)) {
        c_opt = t1_2d.vertices[1];
    } else if (areVerticesEqlApprox(C.position, t1_2d.from_3d.vertices[2].position)) {
        c_opt = t1_2d.vertices[2];
    }
    assert(c_opt != null);
    const c = c_opt.?;
    var a_opt: ?Vec2f = null;
    if (!areVerticesEqlApprox(C.position, t1_2d.from_3d.vertices[0].position) and
        !areVerticesEqlApprox(B.position, t1_2d.from_3d.vertices[0].position))
    {
        a_opt = t1_2d.vertices[0];
    } else if (!areVerticesEqlApprox(C.position, t1_2d.from_3d.vertices[1].position) and
        !areVerticesEqlApprox(B.position, t1_2d.from_3d.vertices[1].position))
    {
        a_opt = t1_2d.vertices[1];
    } else if (!areVerticesEqlApprox(C.position, t1_2d.from_3d.vertices[2].position) and
        !areVerticesEqlApprox(B.position, t1_2d.from_3d.vertices[2].position))
    {
        a_opt = t1_2d.vertices[2];
    }
    assert(a_opt != null);
    const a = a_opt.?;

    var vbc2d: Vec2f = undefined;
    math.substractVec2(&vbc2d, &c, &b);
    const L = math.lengthVec2(&vbc2d);
    const x = (d1 * d1 - d2 * d2 + L * L) / (2 * L);
    const h = @sqrt(@max(0, d1 * d1 - x * x));

    var u: Vec2f = undefined;
    math.normalizeVec2(&u, &vbc2d);
    const v: Vec2f = .{ -u[1], u[0] };

    const x_part: Vec2f = .{ x * u[0], x * u[1] };
    const h_part: Vec2f = .{ h * v[0], h * v[1] };

    var w: Vec2f = undefined;
    math.substractVec2(&w, &a, &b);
    const sideA = math.dotVec2(&v, &w);

    var d: Vec2f = undefined;
    if (sideA > 0) {
        d = .{ b[0] + x_part[0] - h_part[0], b[1] + x_part[1] - h_part[1] };
    } else {
        d = .{ b[0] + x_part[0] + h_part[0], b[1] + x_part[1] + h_part[1] };
    }

    var final_vertices: [3]Vec2f = undefined;
    for (t2.vertices, 0..) |v_3d, i| {
        if (areVerticesEqlApprox(v_3d.position, B.position)) {
            final_vertices[i] = b;
        } else if (areVerticesEqlApprox(v_3d.position, C.position)) {
            final_vertices[i] = c;
        } else {
            final_vertices[i] = d;
        }
    }
    return Triangle2d{
        .vertices = final_vertices,
        .from_3d = t2,
    };
}

fn extractDifferentPoint(t: Triangle, c: Vertex, b: Vertex) Vertex {
    return if (!areVerticesEqlApprox(t.vertices[0].position, b.position) and
        !areVerticesEqlApprox(t.vertices[0].position, c.position))
        t.vertices[0]
    else if (!areVerticesEqlApprox(t.vertices[1].position, b.position) and
        !areVerticesEqlApprox(t.vertices[1].position, c.position))
        t.vertices[1]
    else if (!areVerticesEqlApprox(t.vertices[2].position, b.position) and
        !areVerticesEqlApprox(t.vertices[2].position, c.position))
        t.vertices[2]
    else
        unreachable;
}

fn findAdjacentSide(t1: Triangle, t2: Triangle) ?[2]Vertex {
    var result: [2]Vertex = undefined;
    const emptyVertex = Vertex.init(
        .{ 0, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    @memset(&result, emptyVertex);
    var i: usize = 0;
    for (t1.vertices) |v1| {
        for (t2.vertices) |v2| {
            if (areVerticesEqlApprox(v1.position, v2.position)) {
                if (i < 2) {
                    result[i] = v1;
                }
                i += 1;
                break;
            }
        }
    }
    return if (i != 2) null else result;
}

fn areVerticesEqlApprox(v1: Vec3f, v2: Vec3f) bool {
    if (!std.math.approxEqAbs(f32, v1[0], v2[0], 0.001)) return false;
    if (!std.math.approxEqAbs(f32, v1[1], v2[1], 0.001)) return false;
    if (!std.math.approxEqAbs(f32, v1[2], v2[2], 0.001)) return false;
    return true;
}

fn areVerticesEqlApproxVec2(v1: Vec2f, v2: Vec2f) bool {
    if (!std.math.approxEqAbs(f32, v1[0], v2[0], 0.001)) return false;
    if (!std.math.approxEqAbs(f32, v1[1], v2[1], 0.001)) return false;
    return true;
}

fn makeTwoTriangle() [2]Triangle {
    const a = Vertex.init(
        .{ 0, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const b = Vertex.init(
        .{ 1, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const c = Vertex.init(
        .{ 0, 0, 1 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const d = Vertex.init(
        .{ 2, 1, 1 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const t1 = Triangle.init(a, b, c);
    const t2 = Triangle.init(b, c, d);

    return .{ t1, t2 };
}

test "flatten two triangles" {
    const triangles = makeTwoTriangle();
    const t1 = triangles[0];
    const t2 = triangles[1];

    const t1_2d = Triangle2d.init(
        .{ t1.vertices[0].position[0], t1.vertices[0].position[2] },
        .{ t1.vertices[1].position[0], t1.vertices[1].position[2] },
        .{ t1.vertices[2].position[0], t1.vertices[2].position[2] },
        t1,
    );

    const triangle = flatten(t1, t2, t1_2d);
    const d = triangle.vertices[2];

    try std.testing.expect(areVerticesEqlApproxVec2(d, .{ 2.22474, 1.22474 }));
}

test "find adjacents for t2 triangles" {
    const triangles = makeTwoTriangle();
    const t1 = triangles[0];
    const t2 = triangles[1];

    const adjacents = findAdjacentSide(t1, t2);
    try std.testing.expectEqual(adjacents.?[0], t2.vertices[0]);
    try std.testing.expectEqual(adjacents.?[1], t2.vertices[1]);
}

test "find different point in triangle" {
    const a = Vertex.init(
        .{ 0, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const b = Vertex.init(
        .{ 1, 0, 0 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const c = Vertex.init(
        .{ 0, 0, 1 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const d = Vertex.init(
        .{ 2, 1, 1 },
        .{ 0, 0, 0 },
        .{ 0, 0 },
    );
    const t1 = Triangle.init(a, b, c);
    const t2 = Triangle.init(b, c, d);
    const expected_d = extractDifferentPoint(t2, c, b);
    const expected_a = extractDifferentPoint(t1, c, b);

    try std.testing.expectEqual(expected_d, d);
    try std.testing.expectEqual(expected_a, a);
}

test "generate 3d graph of adjacents triangles for cube" {
    const allocator = std.testing.allocator;
    var geometry = try Geometry.makeCube(allocator);
    defer geometry.deinit(allocator);

    var graph = GeometryGraph3d.init(&geometry);
    defer graph.deinit(allocator);

    try graph.generate(allocator);

    try std.testing.expect(graph.nodes.items.len != 0);
    for (graph.nodes.items) |node| {
        try std.testing.expect(node.neighbors.items.len == 3);
    }
}

test "unwrap 3d geometry to 2d" {
    const allocator = std.testing.allocator;
    var geometry = try Geometry.makeCube(allocator);
    defer geometry.deinit(allocator);

    var graph = GeometryGraph3d.init(&geometry);
    defer graph.deinit(allocator);

    try graph.generate(allocator);
    try std.testing.expect(graph.nodes.items.len != 0);
    for (graph.nodes.items) |node| {
        try std.testing.expect(node.neighbors.items.len == 3);
    }

    var graph2d = try graph.uvUnwrap(allocator);
    defer graph2d.deinit(allocator);

    try std.testing.expectEqual(
        geometry.shape.items.len,
        graph2d.nodes.items.len,
    );

    for (graph2d.nodes.items) |node2d| {
        for (node2d.triangle2d.vertices) |vertex| {
            for (vertex) |coordinate| {
                const roundedCoord: i32 = @intFromFloat(@round(coordinate * 10));
                // for cube, all coordinate will be a multiple of 0.5
                try std.testing.expect(@mod(roundedCoord, 5) == 0);
            }
        }
    }
}

test "unwrap sphrere" {
    const allocator = std.testing.allocator;
    // var geometry = try Geometry.makeCube(allocator);
    const file = try std.fs.cwd().openFile("./assets/sphere.obj", .{ .mode = .read_only });
    defer file.close();

    var file_buffer: [1024]u8 = undefined;
    var reader = file.reader(&file_buffer);
    const reader_interface = &reader.interface;

    var geometry = try obj_parse(reader_interface, allocator);
    defer geometry.deinit(allocator);

    var graph = GeometryGraph3d.init(&geometry);
    defer graph.deinit(allocator);

    try graph.generate(allocator);

    var graph2d = try graph.uvUnwrap(allocator);
    defer graph2d.deinit(allocator);

    graph2d.normalize();
    // graph2d.print();
}
