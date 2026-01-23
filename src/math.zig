const Mat4x4 = [4][4]f32;

pub inline fn identity() Mat4x4 {
    return .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };
}

pub fn multiply(
    result: *Mat4x4,
    m1: *const Mat4x4,
    m2: *const Mat4x4,
) void {
    var r: Mat4x4 = undefined;

    for (0..4) |i| {
        for (0..4) |j| {
            r[i][j] =
                m1[i][0] * m2[0][j] +
                m1[i][1] * m2[1][j] +
                m1[i][2] * m2[2][j] +
                m1[i][3] * m2[3][j];
        }
    }

    result.* = r;
}
