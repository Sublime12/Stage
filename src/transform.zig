const math = @import("math.zig");

pub const Transform = struct {
    const Self = @This();
    mat: math.Mat4x4,

    pub fn init() Self {
        return .{
            .mat = math.identity(),
        };
    }

    pub fn translate(self: *Self, tx: f32, ty: f32, tz: 32) void {
        var translation_matrice = math.identity();
        translation_matrice[0][3] = tx;
        translation_matrice[1][3] = ty;
        translation_matrice[2][3] = tz;

        math.multiply(&self.mat, &self.mat, &translation_matrice);
    }
};
