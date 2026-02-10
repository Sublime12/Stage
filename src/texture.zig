const std = @import("std");
const gl = @cImport(@cInclude("gl.h"));
const Allocator = std.mem.Allocator;
const Vec4u = @import("math.zig").Vec4u;
const Vec3u = @import("math.zig").Vec3u;

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

const TextureFormat = enum(c_int) {
    rgb = gl.GL_RGB,
    rgba = gl.GL_RGBA,
};

pub const TextureData = union(TextureFormat) {
    rgb: []Vec3u,
    rgba: []Vec4u,
};

pub const Texture = struct {
    width: usize,
    height: usize,
    data: TextureData,
    format: TextureFormat,

    pub fn init(
        width: usize,
        height: usize,
        data: TextureData,
    ) Texture {
        switch (data) {
            .rgb => |texture| std.debug.assert(texture.len == width * height),
            .rgba => |texture| std.debug.assert(texture.len == width * height),
        }
        const format = switch(data) {
            .rgb => TextureFormat.rgb,
            .rgba => TextureFormat.rgba,
        };
        return .{
            .width = width,
            .height = height,
            .data = data,
            .format = format,
        };
    }
};
