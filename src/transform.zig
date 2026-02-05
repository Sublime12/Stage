const math = @import("math.zig");
const std = @import("std");

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

        math.multiplyMat4x4(&self.mat, &translation_matrice, &self.mat);
    }

    pub fn rotateX(self: *Self, angle: f32) void {
        var rotateXMatrice = math.identity();
        const cos = @cos(angle);
        const sin = @sin(angle);
        rotateXMatrice[1][1] = cos;
        rotateXMatrice[1][2] = -sin;
        rotateXMatrice[2][1] = sin;
        rotateXMatrice[2][2] = cos;

        math.multiplyMat4x4(&self.mat, &self.mat, &rotateXMatrice);
    }

    pub fn rotateY(self: *Self, angle: f32) void {
        var rotateYMatrice = math.identity();
        const cos = @cos(angle);
        const sin = @sin(angle);
        rotateYMatrice[0][0] = cos;
        rotateYMatrice[0][2] = sin;
        rotateYMatrice[2][0] = -sin;
        rotateYMatrice[2][2] = cos;

        math.multiplyMat4x4(&self.mat, &self.mat, &rotateYMatrice);
    }

    pub fn rotateZ(self: *Self, angle: f32) void {
        var rotateZMatrice = math.identity();
        const cos = @cos(angle);
        const sin = @sin(angle);
        rotateZMatrice[0][0] = cos;
        rotateZMatrice[0][1] = -sin;
        rotateZMatrice[1][0] = sin;
        rotateZMatrice[1][1] = cos;

        math.multiplyMat4x4(&self.mat, &self.mat, &rotateZMatrice);
    }

    pub fn transformVertex(self: *const Self, v: *const Vertex) Vertex {
        var newVertex: Vertex = v.*;
        math.multiplyMat4x4Vec3(&newVertex.position, &self.mat, &v.position);
        return newVertex;
    }
};

test "from expect translation from tx and ty" {
    var transform1 = Transform.init();
    transform1.mat = .{
        .{ 1, 0, 0, 2 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };

    var transform2 = Transform.init();
    transform2.mat = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 2 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };

    var expected = Transform.init();
    expected.mat = .{
        .{ 1, 0, 0, 2 },
        .{ 0, 1, 0, 2 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };

    const actual = Transform.from(&transform1, &transform2);

    try std.testing.expectEqual(expected, actual);
}

test "transform v(1, 0, 0) with rotateY(pi/2) expect (0, 0, -1)" {
    var transform = Transform.init();
    transform.rotateY(std.math.pi / 2.0);

    const expected = Vertex.init(
        .{ 0, 0, -1 },
        .{ 1, 1, 1 },
    );

    const vertex = Vertex.init(
        .{ 1, 0, 0 },
        .{ 1, 1, 1 },
    );

    const actual = transform.transformVertex(&vertex);

    try std.testing.expect(areEqualApproxVertex(&expected, &actual));
}

test "tranform v(0, 0, 1) with rotateX(pi/2) expect (0, 1, 0)" {
    var transform = Transform.init();
    transform.rotateX(std.math.pi / 2.0);

    const expected = Vertex.init(
        .{ 0, -1, 0 },
        .{ 1, 1, 1 },
    );

    const vertex = Vertex.init(
        .{ 0, 0, 1 },
        .{ 1, 1, 1 },
    );

    const actual = transform.transformVertex(&vertex);
    try std.testing.expect(areEqualApproxVertex(&expected, &actual));
}

// translation tx = 1 and rotation Z 90
// (0, 0, 0) -> (1, 0, 0) -> (0, 1, 0)
test "from tx=1 and rotateZ 90 expect (0, 0, 0) -> (0, 1, 0)" {
    var transform1 = Transform.init();
    transform1.translate(1, 0, 0);

    var transform2 = Transform.init();
    transform2.rotateZ(std.math.pi / 2.0);

    const resultTransform = Transform.from(&transform2, &transform1);

    const vertex = Vertex.init(
        .{ 0, 0, 0 },
        .{ 1, 1, 1 },
    );

    const expected = Vertex.init(
        .{ 0, 1, 0 },
        .{ 1, 1, 1 },
    );

    const actual = resultTransform.transformVertex(&vertex);

    // try std.testing.expectApproxEqRel(expected, actual, 0.0001);
    // try std.testing.expectEqual(expected, actual);
    try std.testing.expect(areEqualApproxVertex(&expected, &actual));
}

fn areEqualApproxVertex(v1: *const Vertex, v2: *const Vertex) bool {
    if (@abs(v1.position[0] - v2.position[0]) >= 0.00001) return false;
    if (@abs(v1.position[1] - v2.position[1]) >= 0.00001) return false;
    if (@abs(v1.position[2] - v2.position[2]) >= 0.00001) return false;

    return true;
}
