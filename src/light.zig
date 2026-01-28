const NodeHandle = @import("node.zig").NodeHandle;
const Transform = @import("transform.zig").Transform;
const Vec3 = @import("math.zig").Vector3;
const Vertex = @import("scene.zig").Vertex;
pub const Light = struct {
    const Self = @This();
    // color: Vec3,
    vertex: Vertex,
    strength: f32,
    transform: Transform,
    node: ?NodeHandle,
    // position: Vec3,
    // totalTransform
    // cameraWorld = camera.node.get().totalTransform * camera.transform
    // lumiereWorld = lumiere.node.get().totalTransform * lumiere.transform

    pub fn init(vertex: *const Vertex, strengh: f32) Light {
        return .{
            .vertex = vertex.*,
            .strength = strengh,
            .transform = Transform.init(),
            .node = null,
        };
    }

    pub fn getTransformedVertex(self: *const Self) Vertex {
        if (self.node) |n| {
            const newTransform = Transform.from(&n.get().worldTransform, &self.transform);
            return newTransform.transformVertex(&self.vertex);
        }
        return self.transform.transformVertex(&self.vertex);
    }
};
