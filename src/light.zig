const NodeHandle = @import("node.zig").NodeHandle;
const Transform = @import("transform.zig").Transform;
const Vec3 = @import("math.zig").Vector3;
const Vertex = @import("scene.zig").Vertex;
const math = @import("math.zig");

pub const Light = struct {
    const Self = @This();
    // color: Vec3,
    position: Vec3,
    strength: f32,
    transform: Transform,
    node: ?NodeHandle,
    color: LigthColor,
    // position: Vec3,
    // totalTransform
    // cameraWorld = camera.node.get().totalTransform * camera.transform
    // lumiereWorld = lumiere.node.get().totalTransform * lumiere.transform

    pub fn init(vertex: *const Vec3, strengh: f32) Light {
        return .{
            .position = vertex.*,
            .strength = strengh,
            .transform = Transform.init(),
            .node = null,
            .color = .{
                .ambient = .{ 0.05, 0.05, 0.05 },
                .diffuse = .{ 1.0, 1.0, 1.0 },
                .specular = .{ 1.0, 1.0, 1.0 },
            },
        };
    }

    // pub fn getTransformedVertex(self: *const Self) Vec3 {
    //     if (self.node) |n| {
    //         const newTransform = Transform.from(&n.get().worldTransform, &self.transform);
    //         return newTransform.transformVertex(&self.position);
    //     }
    //     return self.transform.transformVertex(&self.position);
    // }

    pub fn transformPosition(self: *const Self) Vec3 {
        var result: Vec3 = undefined;
        math.multiplyMat4x4Vec3(&result, &self.transform.mat, &self.position);
        return result;
    }
};

const LigthColor = struct {
    ambient: Vec3,
    diffuse: Vec3,
    specular: Vec3,
};
