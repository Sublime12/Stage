const std = @import("std");
const Allocator = std.mem.Allocator;

const NodeHandle = @import("node.zig").NodeHandle;
const Transform = @import("transform.zig").Transform;
const Vec3 = @import("math.zig").Vector3;
const Vertex = @import("scene.zig").Vertex;
const math = @import("math.zig");

pub const LightPool = struct {
    const Self = @This();
    lights: std.ArrayList(Light),
    allocator: Allocator,

    pub fn init(allocator: Allocator) LightPool {
        return .{
            .allocator = allocator,
            .lights = .empty,
        };
    }

    pub fn deinit(self: *Self) void {
        self.lights.deinit(self.allocator);
    }

    pub fn create(self: *Self, light: Light) !LightHandle {
        try self.lights.append(self.allocator, light);
        return .{
            .index = self.lights.items.len - 1,
            .pool = self,
        };
    }
};

pub const LightHandle = struct {
    const Self = @This();
    index: usize,
    pool: *LightPool,

    pub fn get(self: *const Self) *Light {
        return &self.pool.lights.items[self.index];
    }
};

pub const Light = struct {
    const Self = @This();
    // color: Vec3,
    position: Vec3,
    strength: f32,
    transform: Transform,
    node: ?NodeHandle,
    color: LigthColor,
    constant: f32,
    linear: f32,
    quadratic: f32,

    pub fn init(vertex: *const Vec3, strengh: f32) Light {
        return .{
            .position = vertex.*,
            .strength = strengh,
            .transform = Transform.init(),
            .node = null,
            .constant = 1,
            .linear = 0,
            .quadratic = 0,
            .color = .{
                .ambient = .{ 0.05, 0.05, 0.05 },
                .diffuse = .{ 1.0, 1.0, 1.0 },
                .specular = .{ 1.0, 1.0, 1.0 },
            },
        };
    }

    pub fn transformPosition(self: *const Self) Vec3 {
        var result: Vec3 = undefined;
        math.multiplyMat4x4Vec3(&result, &self.transform.mat, &self.position);
        return result;
    }
};

const LigthColor = struct {
    ambient: Vec3,
    diffuse: Vec3,
    specular: Vec3,
};
