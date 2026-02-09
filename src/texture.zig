const std = @import("std");
const Allocator = std.mem.Allocator;
const Vec4u = @import("math.zig").Vec4u;

pub const TexturePool = struct {
    pub const MaxTextures = 3;
    const Self = @This();
    textures: std.ArrayList(Texture),

    pub fn init(allocator: Allocator) !TexturePool {
        return .{
            .textures = try .initCapacity(allocator, MaxTextures),
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.textures.deinit(allocator);
    }

    pub fn create(self: *Self, texture: Texture) TextureHandle {
        self.textures.appendAssumeCapacity(texture);
        return .{
            .pool = self,
            .id = self.textures.items.len - 1,
        };
    }
};

pub const TextureHandle = struct {
    const Self = @This();
    pool: *TexturePool,
    id: usize,

    pub fn get(self: *const Self) *Texture {
        return &self.pool.textures.items[self.id];
    }
};

pub const Texture = struct {
    width: usize,
    height: usize,
    data: []Vec4u,
    // TODO: user must specify the data format used
    // rgb, rgba, gray, gray-alpha, etc...
    // format: FormatEnum

    pub fn init(width: usize, height: usize, data: []Vec4u) Texture {
        std.debug.assert(data.len == width * height);
        return .{
            .width = width,
            .height = height,
            .data = data,
        };
    }
};
