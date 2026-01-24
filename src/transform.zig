const math = @import("math.zig");

const Vertex = @import("scene.zig").Vertex;

pub const Transform = struct {
    const Self = @This();
    mat: math.Mat4x4,

    pub fn init() Self {
        return .{
            .mat = math.identity(),
        };
    }

    pub fn from(t1: *const Transform, t2: *const Transform) Transform {
        var result: math.Mat4x4 = undefined;
        math.multiplyMat4x4(&result, &t1.mat, &t2.mat);

        return .{ .mat = result };
    }

    pub fn translate(self: *Self, tx: f32, ty: f32, tz: f32) void {
        var translation_matrice = math.identity();
        translation_matrice[0][3] = tx;
        translation_matrice[1][3] = ty;
        translation_matrice[2][3] = tz;

        math.multiplyMat4x4(&self.mat, &self.mat, &translation_matrice);
    }

    pub fn transformVertex(self: *const Self, v: *const Vertex) Vertex {
        var newVertex: Vertex = v.*;
        math.multiplyMat4x4Vec3(&newVertex.position, &self.mat, &v.position);
        return newVertex;
    }
};
