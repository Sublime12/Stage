const std = @import("std");

const light_pkg = @import("light.zig");
const texture_pkg = @import("texture.zig");
const geometry_pkg = @import("geometry.zig");

const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const NodeHandle = @import("node.zig").NodeHandle;
const Transform = @import("transform.zig").Transform;
const TextureHandle = texture_pkg.TextureHandle;
const TexturePool = texture_pkg.TexturePool;
const Light = light_pkg.Light;
const LightHandle = light_pkg.LightHandle;
const Vec4u = @import("math.zig").Vec4u;
const Vec3u = @import("math.zig").Vec3u;
// const Vec3f = @import("math.zig").Vec3f;
// const Vec2f = @import("math.zig").Vec2f;

const Vertex = geometry_pkg.Vertex;

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

pub const DIMENSION = 100;
pub fn makeYellowboard() [DIMENSION * DIMENSION]Vec4u {
    var board: [DIMENSION * DIMENSION]Vec4u = undefined;
    for (0..DIMENSION) |i| {
        for (0..DIMENSION) |j| {
            // const i_scaled = i / 5;
            // const j_scaled = j / 5;
            // (255, 223, 34)
            board[j * DIMENSION + i] = .{ 255, 223, 43, 255 };
        }
    }

    return board;
}

pub fn makeColorboard(color: Vec4u) [DIMENSION * DIMENSION]Vec4u {
    var board: [DIMENSION * DIMENSION]Vec4u = undefined;
    for (0..DIMENSION) |i| {
        for (0..DIMENSION) |j| {
            board[j * DIMENSION + i] = color;
        }
    }

    return board;
}

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
