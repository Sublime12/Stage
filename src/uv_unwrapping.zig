const std = @import("std");

const scene = @import("scene.zig");
const math = @import("math.zig");
const link_list = @import("link_list.zig");

const Allocator = std.mem.Allocator;

const Triangle = scene.Triangle;
const Triangle2d = scene.Triangle2d;
const Vertex = scene.Vertex;
const Geometry = scene.Geometry;
const Vec3f = math.Vec3f;
const Vec2f = math.Vec2f;
const DoublyLinkedList = link_list.DoublyLinkedList;

const assert = std.debug.assert;

// have a function taking a list of geometry and return a graph of
// triangles connected to adjencent triangles

// list(Node)
// Node(el, neighbors)
// neighbors(Node)
// Node(triangle3d -> ptr ?Node2d),
// list(node3d) :
// first = nodes3d[0]
// second = nodes3d[1]
// files = []
// while (not emppty(node3d)) {
//      tpop = files.pop();
//      for t.pop.neighbors: stack_nodes.append(neighbor)
//
//      t2d = flatten(tcourant, tpop)
//
//      graph2d.append(t2d)

const Node3d = struct {
    triangle: scene.Triangle,
    neighbors: std.ArrayList(GeometryGraph3d.NodeHandle),
};

const GeometryGraph3d = struct {
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
        const triangles = self.geometry.shape;

        for (triangles.items) |t1| {
            const node: Node3d = .{ .triangle = t1, .neighbors = .empty };
            try self.nodes.append(allocator, node);
        }

        for (self.nodes.items, 0..) |*n1, i| {
            for (self.nodes.items, 0..) |n2, j| {
                if (i == j) continue;

                if (findAdjacentSide(n1.triangle, n2.triangle)) |_| {
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

        // var flattened = std.AutoHashMap(NodeHandle, Triangle2d).init(allocator);
        var flattened = std.AutoArrayHashMap(NodeHandle, Triangle2d).init(allocator);
        defer flattened.deinit();

        assert(self.nodes.items.len >= 2);

        // const second = &self.nodes[1];
        const firstHandle: NodeHandle = .{
            .nodes = &self.nodes,
            .index = 0,
        };

        try visited.putNoClobber(firstHandle, {});
        try nextNodes.append(firstHandle);

        const first = self.nodes.items[0].triangle;
        const first_2d = Triangle2d.init(
            .{ first.vertices[0].position[0], first.vertices[0].position[2] },
            .{ first.vertices[1].position[0], first.vertices[1].position[2] },
            .{ first.vertices[2].position[0], first.vertices[2].position[2] },
            first,
        );
        try flattened.putNoClobber(.{
            .nodes = &self.nodes,
            .index = 0,
        }, first_2d);

        // var i: usize = 0;
        // _ = i;

        while (!nextNodes.empty()) {
            const tpop = nextNodes.popFirst() orelse unreachable;
            // if (visited.contains(tpop)) continue;
            // std.debug.print("current node: {any} {any} {any}: nei {}\n", .{
            //     tpop.triangle.vertices[0].position,
            //     tpop.triangle.vertices[1].position,
            //     tpop.triangle.vertices[2].position,
            //     tpop.neighbors.items.len,
            // });
            for (tpop.get().neighbors.items) |neighbor| {
                // flatten here?
                // if not visited neighbor
                if (visited.contains(neighbor)) continue;
                // defer i += 1;
                // if (i >= 4) break;

                const t1_2d = flattened.get(tpop).?;
                // std.debug.print("tpop{any} {any} {any} neighbord{any} {any} {any}\n", .{
                //     tpop.get().triangle.vertices[0].position,
                //     tpop.get().triangle.vertices[1].position,
                //     tpop.get().triangle.vertices[2].position,
                //     neighbor.get().triangle.vertices[0].position,
                //     neighbor.get().triangle.vertices[1].position,
                //     neighbor.get().triangle.vertices[2].position,
                // });
                const flattenedNeighbor = flatten(
                    tpop.get().triangle,
                    neighbor.get().triangle,
                    t1_2d,
                );

                // std.debug.print("3d: parent{any} {any} {any} -> child{any} {any} {any}\n", .{
                //     tpop.get().triangle.vertices[0].position,
                //     tpop.get().triangle.vertices[1].position,
                //     tpop.get().triangle.vertices[2].position,
                //     neighbor.get().triangle.vertices[0].position,
                //     neighbor.get().triangle.vertices[1].position,
                //     neighbor.get().triangle.vertices[2].position,
                // });
                //
                //
                // std.debug.print("2d: parent{any} -> child{any}\n", .{
                //     t1_2d.vertices,
                //     flattenedNeighbor.vertices,
                // });

                std.debug.print("2d: child{any}\n", .{
                    flattenedNeighbor.vertices,
                });

                try flattened.putNoClobber(neighbor, flattenedNeighbor);
                try visited.putNoClobber(neighbor, {});
                try nextNodes.append(neighbor);
            }
            // try visited.putNoClobber(tpop, {});
        }

        var it = flattened.iterator();
        while (it.next()) |entry| {
            const triangle2d = entry.value_ptr;
            std.debug.print("t = {any}\n", .{triangle2d.vertices});
        }
        unreachable;
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

const Node2d = struct {
    triangle: scene.Triangle,
    neighbors: std.ArrayList(Node2d),
};

const GeometryGraph2d = struct {
    const Self = @This();

    nodes: std.ArrayList(Node2d),
    geometry: *const Geometry,
};

// t12d
pub fn flatten(t1: Triangle, t2: Triangle, t1_2d: Triangle2d) Triangle2d {
    const adjancentSide = findAdjacentSide(t1, t2);
    const B = adjancentSide.?[0];
    const C = adjancentSide.?[1];
    const D = extractDifferentPoint(t2, C, B);
    // const A = extractDifferentPoint(t1, C, B);
    var vbc3d: Vec3f = undefined;
    var vbd3d: Vec3f = undefined;
    math.substractVec3(&vbc3d, &C.position, &B.position);
    math.substractVec3(&vbd3d, &D.position, &B.position);
    // const dot = math.dotVec3(&vbc3d, &vbd3d);
    // const lengthBc = math.lengthVec3(&vbc3d);
    // const lengthBd = math.lengthVec3(&vbd3d);
    // const cos = dot / (lengthBc * lengthBd);
    // const sin = @sqrt(1 - cos * cos);
    var vcd3d: Vec3f = undefined;
    math.substractVec3(&vcd3d, &D.position, &C.position);
    const d2 = math.lengthVec3(&vcd3d); // Distance C to D
    const d1 = math.lengthVec3(&vbd3d); // Distance B to D

    // const b: Vec2f = .{ B.position[0], B.position[2] };
    // const c: Vec2f = .{ C.position[0], C.position[2] };
    // B == t1_2d.3d.v1 if true
    // b = t1_2d.v1
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
    // const a: Vec2f = .{ A.position[0], A.position[2] };
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

    // var vbc2d: Vec2f = undefined;
    // math.substractVec2(&vbc2d, &c, &b);
    // const d1 = math.lengthVec3(&vbd3d);

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
    // const xlocal = d1 * cos;
    // const zlocal = d1 * sin;
    //
    // const xlocal_u: Vec2f = .{ xlocal * u[0], xlocal * u[1] };
    // const zlocal_v: Vec2f = .{ zlocal * v[0], zlocal * v[1] };
    // var local_uv: Vec2f = undefined;

    var w: Vec2f = undefined;
    math.substractVec2(&w, &a, &b);
    const sideA = math.dotVec2(&v, &w);
    // const sideA = math.dotVec2(&w, &v);
    // if (sideA > 0) {
    //     math.substractVec2(&local_uv, &xlocal_u, &zlocal_v);
    // } else {
    //     math.addVec2(&local_uv, &xlocal_u, &zlocal_v);
    // }

    var d: Vec2f = undefined;
    if (sideA > 0) {
        d = .{ b[0] + x_part[0] - h_part[0], b[1] + x_part[1] - h_part[1] };
    } else {
        d = .{ b[0] + x_part[0] + h_part[0], b[1] + x_part[1] + h_part[1] };
    }

    // const d: Vec2f = .{ b[0] + local_uv[0], b[1] + local_uv[1] };
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
    // const flattenT2 = Triangle2d.init(
    //     b,
    //     c,
    //     d,
    //     t2,
    // );
    // return flattenT2;
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

    // std.debug.print("{f}\n", .{graph});
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
    for (graph.nodes.items, 0..) |node, i| {
        _ = i;
        // std.debug.print("node {} len: {}\n", .{ i, node.neighbors.items.len });
        try std.testing.expect(node.neighbors.items.len == 3);
    }

    _ = try graph.uvUnwrap(allocator);
}
