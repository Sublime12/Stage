const std = @import("std");
const math = std.math;

const scene_pkg = @import("scene.zig");
const node = @import("node.zig");
const stage = @import("app.zig");
const camera_pkg = @import("camera.zig");
const light_pkg = @import("light.zig");
const texture_pkg = @import("texture.zig");

const Geometry = scene_pkg.Geometry;
const Scene = scene_pkg.Scene;
const Node = node.Node;
const NodePool = node.NodePool;
const App = stage.App;
const Camera = camera_pkg.Camera;
const Light = light_pkg.Light;
const LightPool = light_pkg.LightPool;
const Vertex = scene_pkg.Vertex;
const TexturePool = texture_pkg.TexturePool;
const Texture = texture_pkg.Texture;

const chessboard = @import("scene.zig").makeChessboard;
const diskboard = @import("scene.zig").makeDisk;

const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});

const gl = @cImport(@cInclude("gl.h"));
const cmath = @cImport(@cInclude("linmath.h"));

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try App.init("Stage window", 640, 480);
    defer app.deinit();

    var scene = try Scene.init(allocator);
    defer scene.deinit();

    var pool = NodePool.init(allocator);
    defer pool.deinit();

    var texturePool = try TexturePool.init(allocator);
    defer texturePool.deinit(allocator);

    const cubeGeo = try Geometry.makeCube(allocator);

    var data = chessboard();
    var disk = diskboard();

    const texture1 = texturePool.create(
        Texture.init(scene_pkg.DIMENSION, scene_pkg.DIMENSION, &data),
    );

    const texture2 = texturePool.create(
        Texture.init(scene_pkg.DIMENSION, scene_pkg.DIMENSION, &disk),
    );

    var node1 = try pool.create(Node.init(cubeGeo, texture1));

    try scene.addRoot(node1);
    scene.addTexture(texture1);
    scene.addTexture(texture2);

    var camera = Camera.init(math.pi / 4.0, 640.0 / 420.0, 0.01, 100);
    node1.get().transform.translate(0, 0, 0.0);
    // TODO: Adjust the specular ligth when camara eye move
    camera.lookAt(.{ -1.5, -1.0, -1.5 }, .{ 0.1, 0.1, 0.1 }, .{ 0.0, 1.0, 0.0 });

    // const cubeGeo2 = try Geometry.makeTriangle(allocator, 1, 1, 1);
    const cubeGeo2 = try Geometry.makeCube(allocator);
    var node2 = try pool.create(Node.init(cubeGeo2, texture2));
    node2.get().transform.translate(2, 0, 0);

    try node1.get().addChild(allocator, node2);

    var lightPool = LightPool.init(allocator);
    defer lightPool.deinit();

    var light = try lightPool.create(Light.init(&.{ 1.5, 1.5, 1.5 }, 2.0));
    light.get().color.ambient = .{ 1, 1, 1 };
    light.get().color.diffuse = .{ 0.3, 0.3, 0.3 };
    light.get().color.specular = .{ 1, 0, 0 };

    // light.get().quadratic = 1;
    // light.color.specular = .{0.3, 0.3, 0.3};
    light.get().node = node2;
    scene.addLight(light);

    var light2 = try lightPool.create(Light.init(&.{ -1.5, -1.5, -1.5 }, 2.0));
    light2.get().color.ambient = .{ 0.2, 0.1, 0.1 };
    light2.get().color.specular = .{ 0, 1, 0 };

    scene.addLight(light2);

    const window = glfw.glfwGetCurrentContext();

    while (glfw.glfwWindowShouldClose(window) == 0) {
        try app.render(allocator, &scene, &camera);
        // light.vertex.position[0] += 0.0001;
        // light.transform.translate(0.003, 0, 0);
        // scene.addLight(light);

        // node2.get().transform.rotateX(0.01);

        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_UP) == glfw.GLFW_PRESS) {
            std.debug.print("UP\n", .{});
            camera.view.translate(0, -0.01, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_DOWN) == glfw.GLFW_PRESS) {
            std.debug.print("DOWN\n", .{});
            camera.view.translate(0, 0.01, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_RIGHT) == glfw.GLFW_PRESS) {
            std.debug.print("RIGHT\n", .{});
            camera.view.translate(0.01, 0, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_LEFT) == glfw.GLFW_PRESS) {
            std.debug.print("LEFT\n", .{});
            camera.view.translate(-0.01, 0, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_W) == glfw.GLFW_PRESS) {
            std.debug.print("FORWARD\n", .{});
            camera.view.translate(0, 0, 0.01);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_S) == glfw.GLFW_PRESS) {
            std.debug.print("BACKWARD\n", .{});
            camera.view.translate(0, 0, -0.01);
        }

        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_N) == glfw.GLFW_PRESS) {
            std.debug.print("rotate left\n", .{});
            camera.view.rotateY(-0.01);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_M) == glfw.GLFW_PRESS) {
            std.debug.print("rotate right\n", .{});
            camera.view.rotateY(0.01);
        }

        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_H) == glfw.GLFW_PRESS) {
            std.debug.print("rotate right\n", .{});
            camera.view.rotateX(0.01);
        }

        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_B) == glfw.GLFW_PRESS) {
            std.debug.print("rotate right\n", .{});
            camera.view.rotateX(-0.01);
        }

        // const radius:f32 = 10.0;
        // const camX:f32 = @sin(@as(f32, @floatCast(glfw.glfwGetTime()))) * radius;
        // const camZ:f32 = @cos(@as(f32, @floatCast(glfw.glfwGetTime()))) * radius;
        // camera.lookAt(.{camX, 0.0, camZ}, .{0.0, 0.0, 0.0}, .{0.0, 1.0, 0.0});

        // node5.get().transform.rotateY(math.pi / 300.0);
    }
}

test "test checkboard" {
    const board = chessboard();

    for (board) |row| {
        for (row) |v| {
            if (v[0] == 0) {
                std.debug.print("{} ", .{v[0]});
            } else {
                std.debug.print("{} ", .{v[0]});
            }
        }
        std.debug.print("\n", .{});
    }
}
