const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const NodeHandle = @import("node.zig").NodeHandle;
const Transform = @import("transform.zig").Transform;
const light_pkg = @import("light.zig");
const texture_pkg = @import("texture.zig");
const TextureHandle = texture_pkg.TextureHandle;
const TexturePool = texture_pkg.TexturePool;
const Light = light_pkg.Light;
const LightHandle = light_pkg.LightHandle;
const Vec4u = @import("math.zig").Vec4u;
const Vec3u = @import("math.zig").Vec3u;
const Vec2f = @import("math.zig").Vec2f;

pub const Scene = struct {
    const Self = @This();
    pub const MaxLights = 5;

    root: ?NodeHandle,
    lights: std.ArrayList(LightHandle),
    textures: std.ArrayList(TextureHandle),
    allocator: Allocator,

    /// Initilize the scene with an empty tree.
    pub fn init(allocator: Allocator) !Scene {
        return .{
            .root = null,
            .allocator = allocator,
            .lights = try std.ArrayList(LightHandle).initCapacity(allocator, MaxLights),
            .textures = try std.ArrayList(TextureHandle).initCapacity(allocator, TexturePool.MaxTextures),
        };
    }

    pub fn deinit(self: *Self) void {
        self.lights.deinit(self.allocator);
        self.textures.deinit(self.allocator);
    }

    pub fn addLight(self: *Self, light: LightHandle) void {
        self.lights.appendAssumeCapacity(light);
    }

    pub fn addTexture(self: *Self, texture: TextureHandle) void {
        self.textures.appendAssumeCapacity(texture);
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
        const white = .{ 1.0, 1.0, 1.0 };
        const triangle1 = Triangle.init(
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = white, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = white, .textCoord = .{ 0, 0 } },
        );

        const triangle2 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = white, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = white, .textCoord = .{ 0, 1 } },
        );

        // Face 2
        const triangle3 = Triangle.init(
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = white, .textCoord = .{ 0, 0 } },
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
        );

        const triangle4 = Triangle.init(
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = white, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
        );

        // Face 3
        const triangle5 = Triangle.init(
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = white, .textCoord = .{ 0, 0 } },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = white, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
        );

        const triangle6 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.5 }, .color = white, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = white, .textCoord = .{ 1, 0 } },
        );

        // Face 4
        const triangle7 = Triangle.init(
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = white, .textCoord = .{ 0, 0 } },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
        );

        const triangle8 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.5 }, .color = white, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
        );

        // Face 4
        const triangle9 = Triangle.init(
            .{ .position = .{ 0.0, 0.0, 0.0 }, .color = white, .textCoord = .{ 0, 0 } },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
        );

        const triangle10 = Triangle.init(
            .{ .position = .{ 0.5, 0.0, 0.5 }, .color = white, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.0, 0.0, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.0, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
        );

        // Face 6
        const triangle11 = Triangle.init(
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.5, 0.0 }, .color = white, .textCoord = .{ 0, 0 } },
        );

        const triangle12 = Triangle.init(
            .{ .position = .{ 0.5, 0.5, 0.5 }, .color = white, .textCoord = .{ 1, 1 } },
            .{ .position = .{ 0.5, 0.5, 0.0 }, .color = white, .textCoord = .{ 1, 0 } },
            .{ .position = .{ 0.0, 0.5, 0.5 }, .color = white, .textCoord = .{ 0, 1 } },
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

pub const DIMENSION = 100;
pub fn makeChessboard() [DIMENSION * DIMENSION]Vec4u {
    var board: [DIMENSION * DIMENSION]Vec4u = undefined;
    for (0..DIMENSION) |i| {
        for (0..DIMENSION) |j| {
            const i_scaled = i / 5;
            const j_scaled = j / 5;
            board[j * DIMENSION + i] = (if ((i_scaled + j_scaled) % 2 == 0)
                .{ 0, 0, 0, 0 }
            else
                .{ 255, 255, 255, 255 });
        }
    }

    return board;
}

pub fn makeDisk() [DIMENSION * DIMENSION]Vec3u {
    var board: [DIMENSION * DIMENSION]Vec3u = undefined;

    for (0..DIMENSION) |i| {
        for (0..DIMENSION) |j| {
            const x_center: f32 = DIMENSION / 2;
            const y_center: f32 = DIMENSION / 2;

            const i_f: f32 = @floatFromInt(i);
            const j_f: f32 = @floatFromInt(j);

            const value = @sqrt(
                (i_f - x_center) * (i_f - x_center) + (j_f - y_center) * (j_f - y_center),
            );
            if (value < DIMENSION / 2) {
                board[i + j * DIMENSION] = .{ 10, 75, 150 };
            } else {
                board[i + j * DIMENSION] = .{ 255, 255, 255 };
            }
        }
    }

    return board;
}

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

    pub fn init(v1: Vec2f, v2: Vec2f, v3: Vec2f) Triangle2d {
        return .{
            .vertices = .{ v1, v2, v3 },
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
