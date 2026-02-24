const std = @import("std");
const math = std.math;

const scene_pkg = @import("scene.zig");
const node = @import("node.zig");
const stage = @import("app.zig");
const camera_pkg = @import("camera.zig");
const light_pkg = @import("light.zig");
const texture_pkg = @import("texture.zig");
const uv_unwrapping_pkg = @import("uv_unwrapping.zig");
const stb = @cImport(@cInclude("stb_image.h"));

const obj_parse = @import("obj_parser.zig").obj_parse;

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
const TextureData = texture_pkg.TextureData;
const GeometryGraph3d = uv_unwrapping_pkg.GeometryGraph3d;
const GeometryGraph2d = uv_unwrapping_pkg.GeometryGraph2d;

const chessboard = @import("scene.zig").makeChessboard;
const diskboard = @import("scene.zig").makeDisk;
const yellowboard = @import("scene.zig").makeYellowboard;
const colorboard = @import("scene.zig").makeColorboard;

const BUFFER_LENGTH = 1024 * 10;

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

    // const cubeGeo = try Geometry.makeCube(allocator);
    var board = yellowboard();

    const file = try std.fs.cwd().openFile("./assets/sphere.obj", .{ .mode = .read_only });
    defer file.close();

    var file_buffer: [BUFFER_LENGTH]u8 = undefined;
    var reader = file.reader(&file_buffer);
    const reader_interface = &reader.interface;

    const scale = 0.7;
    const baseColor = .{ 1.0 * scale, 0.874 * scale, 0.169 * scale };

    const sphereGeo = try obj_parse(reader_interface, allocator, baseColor);

    var graph3d = GeometryGraph3d.init(&sphereGeo);
    defer graph3d.deinit(allocator);
    try graph3d.generate(allocator);

    var graph2d = try graph3d.uvUnwrap(allocator);
    defer graph2d.deinit(allocator);

    const earthGeo = try sphereGeo.clone(allocator);
    const data = TextureData{ .rgba = &board };

    // var diskb = diskboard();
    // const disk = TextureData{ .rgb = &diskb };

    const texture1 = texturePool.create(
        Texture.init(scene_pkg.DIMENSION, scene_pkg.DIMENSION, data),
    );

    var width: c_int = 0;
    var height: c_int = 0;
    var nrChannels: c_int = 0;
    const image = stb.stbi_load("assets/texture_earth.png", &width, &height, &nrChannels, 3);
    defer stb.stbi_image_free(image);

    const width_u: usize = @intCast(width);
    const height_u: usize = @intCast(height);

    const raw_slice = image[0 .. width_u * height_u * 3];
    const rgba_slice: []const [3]u8 = @ptrCast(@alignCast(raw_slice));

    const earthT = TextureData{ .rgb = rgba_slice };
    const texture2 = texturePool.create(
        Texture.init(width_u, height_u, earthT),
);
    // const texture2 = TextureData{ .rgba = image };

    std.debug.print("w: {}, h: {}, :nrChannels: {}\n", .{ width, height, nrChannels});

    // var earthMap = colorboard(.{0, 84, 119, 255});
    // const earthT = TextureData{ .rgba = &earthMap };
    // const texture2 = texturePool.create(
    //     Texture.init(scene_pkg.DIMENSION, scene_pkg.DIMENSION, earthT),
    // );

    var sunNode = try pool.create(Node.init(sphereGeo, texture1));
    // sunNode.get().transform.scale(0.2);
    sunNode.get().transform.translate(0, 0, 0.0);
    // sunNode.get().geometry.?.setBaseColor(.{ 0 , 0 , 0});

    try scene.addRoot(sunNode);
    scene.addTexture(texture1);
    scene.addTexture(texture2);

    var camera = Camera.init(math.pi / 4.0, 640.0 / 420.0, 0.01, 100);
    // TODO: Adjust the specular ligth when camara eye move
    camera.lookAt(.{ 0, 25, 0 }, .{ 0.1, 0.1, 0.1 }, .{ 0.0, 1.0, 0.0 });

    // const cubeGeo2 = try Geometry.makeTriangle(allocator, 1, 1, 1);
    // const cubeGeo2 = try Geometry.makeCube(allocator);
    // _ = cubeGeo2;
    var earthNode = try pool.create(Node.init(earthGeo, texture2));
    // earthNode.get().geometry.?.setColor();
    earthNode.get().transform.translate(10, 0, 0);
    earthNode.get().transform.scale(2);
    earthNode.get().geometry.?.setBaseColor(.{0, 0, 0});
    earthNode.get().transform.scale(0.3);

    var moonMap = colorboard(.{174, 46, 74, 0});
    const moonT = TextureData{ .rgba = &moonMap};
    const texture3 = texturePool.create(
        Texture.init(scene_pkg.DIMENSION, scene_pkg.DIMENSION, moonT),
    );

    var moonGeo = try sphereGeo.clone(allocator);
    moonGeo.setBaseColor(.{ 0.0, 0.0, 0.0 });
    const moonNode = try pool.create(Node.init(moonGeo, texture3));
    moonNode.get().transform.translate(3, 0, 0);
    try earthNode.get().addChild(allocator, moonNode);

    try sunNode.get().addChild(allocator, earthNode);

    var lightPool = LightPool.init(allocator);
    defer lightPool.deinit();

    var light = try lightPool.create(Light.init(&.{ 0, 0, 0 }, 2.0));
    light.get().color.ambient = .{ 1, 1, 1 };
    light.get().color.diffuse = .{ 0.3, 0.3, 0.3 };
    light.get().color.specular = .{ 1, 0, 0 };
    light.get().constant = 0.4;

    // light.get().quadratic = 1;
    // light.color.specular = .{0.3, 0.3, 0.3};
    light.get().node = earthNode;
    scene.addLight(light);

    // var light2 = try lightPool.create(Light.init(&.{ -1.5, -1.5, -1.5 }, 2.0));
    // light2.get().color.ambient = .{ 0.2, 0.1, 0.1 };
    // light2.get().color.specular = .{ 0, 1, 0 };

    // scene.addLight(light2);
    scene.addTexture(texture3);

    const window = glfw.glfwGetCurrentContext();

    while (glfw.glfwWindowShouldClose(window) == 0) {
        try app.render(allocator, &scene, &camera);
        // light.vertex.position[0] += 0.0001;
        // light.transform.translate(0.003, 0, 0);
        // scene.addLight(light);

        // node2.get().transform.rotateX(0.01);
        // sunNode.get().transform.rotateY(0.01);
        // earthNode.get().transform.rotateY(0.07);

        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_UP) == glfw.GLFW_PRESS) {
            std.debug.print("UP\n", .{});
            camera.view.translate(0, -0.1, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_DOWN) == glfw.GLFW_PRESS) {
            std.debug.print("DOWN\n", .{});
            camera.view.translate(0, 0.1, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_RIGHT) == glfw.GLFW_PRESS) {
            std.debug.print("RIGHT\n", .{});
            camera.view.translate(0.1, 0, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_LEFT) == glfw.GLFW_PRESS) {
            std.debug.print("LEFT\n", .{});
            camera.view.translate(-0.1, 0, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_W) == glfw.GLFW_PRESS) {
            std.debug.print("FORWARD\n", .{});
            camera.view.translate(0, 0, 0.1);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_S) == glfw.GLFW_PRESS) {
            std.debug.print("BACKWARD\n", .{});
            camera.view.translate(0, 0, -0.1);
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
    }
}
