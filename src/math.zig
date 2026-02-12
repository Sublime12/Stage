const std = @import("std");

pub const Mat4x4 = [4][4]f32;
pub const Vector3 = [3]f32;
pub const Vec4u = [4]u8;
pub const Vec3u = [3]u8;
pub const Vec2f = [2]f32;

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

pub fn substractVec3(result: *Vector3, vec1: *const Vector3, vec2: *const Vector3) void {
    result.* = .{
        vec1[0] - vec2[0],
        vec1[1] - vec2[1],
        vec1[2] - vec2[2],
    };
}

pub fn normalizeVec3(result: *Vector3, vec: *const Vector3) void {
    const length = @sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
    result.* = .{
        vec[0] / length,
        vec[1] / length,
        vec[2] / length,
    };
}

pub fn crossVec3(result: *Vector3, vec1: *const Vector3, vec2: *const Vector3) void {
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
    return (vec1[0] * vec2[0]) + (vec1[1] * vec2[1]) + (vec1[2] * vec2[2]);
}

fn generateRandomMat4x4(rand: std.Random) Mat4x4 {
    var result: Mat4x4 = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };

    for (0..4) |i| {
        for (0..4) |j| {
            result[i][j] = rand.float(f32);
        }
    }

    return result;
}

fn lengthVec3(vec: *const Vector3) f32 {
    return @sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
}

test "expect identity return an identity 4x4 matrix" {
    const expected: Mat4x4 = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };
    const actual: Mat4x4 = identity();

    try std.testing.expectEqual(expected, actual);
}

test "expect multiplyMat4x4 with any matrix by identity return the orignal matrix" {
    var prng = std.Random.DefaultPrng.init(5);

    const m1: Mat4x4 = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };
    const m2: Mat4x4 = generateRandomMat4x4(prng.random());

    var actual: Mat4x4 = undefined;
    multiplyMat4x4(&actual, &m1, &m2);

    try std.testing.expectEqual(m2, actual);
}

test "expect multiplyMat4x4 return the product of m1 multiply by m2" {
    const m1: Mat4x4 = .{
        .{ 5, 7, 9, 10 },
        .{ 2, 3, 3, 8 },
        .{ 8, 10, 2, 3 },
        .{ 3, 3, 4, 8 },
    };
    const m2: Mat4x4 = .{
        .{ 3, 10, 12, 18 },
        .{ 12, 1, 4, 9 },
        .{ 9, 10, 12, 2 },
        .{ 3, 12, 4, 10 },
    };
    const expected: Mat4x4 = .{
        .{ 210, 267, 236, 271 },
        .{ 93, 149, 104, 149 },
        .{ 171, 146, 172, 268 },
        .{ 105, 169, 128, 169 },
    };

    var actual: Mat4x4 = undefined;
    multiplyMat4x4(&actual, &m1, &m2);

    try std.testing.expectEqual(expected, actual);
}

test "expect multiplyMat4x4Vec3 with any vector by identity matrix return the orignal vector" {
    const v: Vector3 = .{ 5, 6, 1 };
    const m: Mat4x4 = .{
        .{ 2, 5, 9, 7 },
        .{ 6, 2, 8, 5 },
        .{ 4, 0, 4, 4 },
        .{ 1, 4, 2, 7 },
    };
    const expected: Vector3 = .{ 56, 55, 28 };

    var actual: Vector3 = undefined;
    multiplyMat4x4Vec3(&actual, &m, &v);

    try std.testing.expectEqual(expected, actual);
}

test "expect multiplyMat4x4Vec3 return the product of m multiply by v" {
    var prng = std.Random.DefaultPrng.init(5);
    const rand = prng.random();

    const v: Vector3 = .{ rand.float(f32), rand.float(f32), rand.float(f32) };
    const m: Mat4x4 = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };

    var actual: Vector3 = undefined;
    multiplyMat4x4Vec3(&actual, &m, &v);

    try std.testing.expectEqual(v, actual);
}

test "expect substractVec3 return the difference between vec1 and vec2" {
    const vec1: Vector3 = .{ 7, 3, 6 };
    const vec2: Vector3 = .{ 4, 0, 8 };

    const expected: Vector3 = .{ 3, 3, -2 };
    var actual: Vector3 = undefined;

    substractVec3(&actual, &vec1, &vec2);

    try std.testing.expectEqual(expected, actual);
}

test "expect normalizeVec3 normalize to length of 1" {
    const vec: Vector3 = .{ 1, 4, 2 };

    const length = lengthVec3(&vec);
    const expected: Vector3 = .{ vec[0] / length, vec[1] / length, vec[2] / length };
    var actual: Vector3 = undefined;

    normalizeVec3(&actual, &vec);

    try std.testing.expect(@abs(lengthVec3(&actual) - 1) <= 0.00001);
    try std.testing.expectEqual(expected, actual);
}

test "expect crossVec3 return 0 vector with parallel vector" {
    const vec1: Vector3 = .{ 1, 2, 3 };
    const vec2: Vector3 = .{ 3, 6, 9 };

    const expected: Vector3 = .{ 0, 0, 0 };
    var actual: Vector3 = undefined;

    crossVec3(&actual, &vec1, &vec2);

    try std.testing.expectEqual(expected, actual);
}

test "expect crossVec3 return the cross product of two vector" {
    const vec1: Vector3 = .{ 7, 5, 4 };
    const vec2: Vector3 = .{ 6, 2, 0 };

    const expected: Vector3 = .{ -8, 24, -16 };
    var actual: Vector3 = undefined;

    crossVec3(&actual, &vec1, &vec2);

    try std.testing.expectEqual(expected, actual);
}

test "exoect dotVec3 return 0 with perpendicular vector" {
    const vec1: Vector3 = .{ 0, 0, 1 };
    const vec2: Vector3 = .{ 0, 1, 0 };

    const expected: f32 = 0;
    const actual: f32 = dotVec3(&vec1, &vec2);

    try std.testing.expect(@abs(actual - expected) <= 0.00001);
}

test "exoect dotVec3 return the dot product of vec1 and vec2" {
    const vec1: Vector3 = .{ 5, 2, 0 };
    const vec2: Vector3 = .{ 9, 8, 4 };

    const expected: f32 = 61;
    const actual: f32 = dotVec3(&vec1, &vec2);

    try std.testing.expectEqual(expected, actual);
}
