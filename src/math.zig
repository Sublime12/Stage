pub const Mat4x4 = [4][4]f32;
pub const Vector3 = [3]f32;

pub inline fn identity() Mat4x4 {
    return .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };
}

pub fn multiplyMat4x4(
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

pub fn multiplyMat4x4Vec3(
    result: *Vector3,
    m: *const Mat4x4,
    v: *const Vector3,
) void {
    const x = v[0];
    const y = v[1];
    const z = v[2];

    result.* = .{
        m[0][0] * x + m[0][1] * y + m[0][2] * z + m[0][3],
        m[1][0] * x + m[1][1] * y + m[1][2] * z + m[1][3],
        m[2][0] * x + m[2][1] * y + m[2][2] * z + m[2][3],
    };
}

pub fn substractVec3(
    result: *Vector3,
    vec1: *const Vector3,
    vec2: *const Vector3
) void {
    result.* = .{
        vec1[0] - vec2[0],
        vec1[1] - vec2[1],
        vec1[2] - vec2[2],
    };
}

pub fn normalizeVec3(
    result: *Vector3,
    vec: *const Vector3
) void {
    const length = @sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]); 
    result.* = .{
        vec[0] / length,
        vec[1] / length,
        vec[2] / length,
    };
}

pub fn crossVec3(
    result: *Vector3,
    vec1: *const Vector3,
    vec2: *const Vector3
) void {
    result.* = .{
        vec1[1] * vec2[2] - vec1[2] * vec2[1],
        vec1[2] * vec2[0] - vec1[0] * vec2[2],
        vec1[0] * vec2[1] - vec1[1] * vec2[0],
    };
}

pub fn dotVec3(
    vec1: *const Vector3,
    vec2: *const Vector3,
) f32 {
    return (vec1[0] * vec2[0])
            + (vec1[1] * vec2[1])
            + (vec1[2] * vec2[2]); 
}
