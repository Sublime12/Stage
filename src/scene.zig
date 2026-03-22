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
