const std = @import("std");

const Transform = @import("transform.zig").Transform;

pub const Camera = struct {
    projection: Transform,
    view: Transform,

    pub fn init(fov: f32, ratio: f32, near: f32, fear: f32) Camera {
        var projection = Transform.init();
        const scale = @tan(fov * 0.5) * near;
        const right = ratio * scale;
        const left = -right;
        const top = scale;
        const bottom = -top;

        projection.mat[0][0] = 2 * near / (right - left);
        projection.mat[1][0] = 0;
        projection.mat[2][0] = 0;
        projection.mat[3][0] = 0;

        projection.mat[0][1] = 0;
        projection.mat[1][1] = 2 * near / (top - bottom);
        projection.mat[2][1] = 0;
        projection.mat[3][1] = 0;

        projection.mat[0][2] = (right + left) / (right - left);
        projection.mat[1][2] = (top + bottom) / (top - bottom);
        projection.mat[2][2] = -(fear + near) / (fear - near);
        projection.mat[3][2] = -1;

        projection.mat[0][3] = 0;
        projection.mat[1][3] = 0;
        projection.mat[2][3] = -2 * fear * near / (fear - near);
        projection.mat[3][3] = 0;

        // projection.mat[0][0] = 2 * near / (right - left);
        // projection.mat[0][1] = 0;
        // projection.mat[0][2] = 0;
        // projection.mat[0][3] = 0;

        // projection.mat[1][0] = 0;
        // projection.mat[1][1] = 2 * near / (top - bottom);
        // projection.mat[1][2] = 0;
        // projection.mat[1][3] = 0;

        // projection.mat[2][0] = (right + left) / (right - left);
        // projection.mat[2][1] = (top + bottom) / (top - bottom);
        // projection.mat[2][2] = -(fear + near) / (fear - near);
        // projection.mat[2][3] = -1;

        // projection.mat[3][0] = 0;
        // projection.mat[3][1] = 0;
        // projection.mat[3][2] = -2 * fear * near / (fear - near);
        // projection.mat[3][3] = 0;

        var view = Transform.init();
        view.mat[2][2] = 1;

        std.debug.print("View: \n", .{});
        for (0..4) |i| {
            for (0..4) |j| {
                std.debug.print("{}\t", .{view.mat[i][j]});
            }
            std.debug.print("\n", .{});
        }

        std.debug.print("proj : \n", .{});
        for (0..4) |i| {
            for (0..4) |j| {
                std.debug.print("{}\t", .{projection.mat[i][j]});
            }
            std.debug.print("\n", .{});
        }

        return .{
            .projection = projection,
            .view = view,
        };
    }
};
