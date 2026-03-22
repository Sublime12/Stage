const std = @import("std");
const gl = @cImport(@cInclude("gl.h"));
const Allocator = std.mem.Allocator;
const Vec4u = @import("math.zig").Vec4u;
const Vec3u = @import("math.zig").Vec3u;

pub const TexturePool = struct {
    pub const MaxTextures = 8;
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
    rgb: []const Vec3u,
    rgba: []const Vec4u,
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
        const format = switch (data) {
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
