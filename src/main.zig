const std = @import("std");
const math = std.math;

const scene_pkg = @import("scene.zig");
const geometry_pkg = @import("geometry.zig");
const node = @import("node.zig");
const stage = @import("app.zig");
const camera_pkg = @import("camera.zig");
const light_pkg = @import("light.zig");
const texture_pkg = @import("texture.zig");
const uv_unwrapping_pkg = @import("uv_unwrapping.zig");
const stb = @cImport(@cInclude("stb_image.h"));

const obj_parse = @import("obj_parser.zig").obj_parse;

const Geometry = geometry_pkg.Geometry;
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
const NodeHandle = node.NodeHandle;
const Random = std.Random;

const chessboard = scene_pkg.makeChessboard;
const diskboard = scene_pkg.makeDisk;
const yellowboard = texture_pkg.makeYellowboard;
const colorboard = scene_pkg.makeColorboard;

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

    var app = try App.init("Stage window", 1200, 900);
    defer app.deinit();

    var scene = try Scene.init(allocator);
    defer scene.deinit();

    var pool = NodePool.init(allocator);
    defer pool.deinit();

    var texturePool = try TexturePool.init(allocator);
    defer texturePool.deinit(allocator);

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
    var board = yellowboard();
    const data = TextureData{ .rgba = &board };

    const starTexture = texturePool.create(
        Texture.init(texture_pkg.DIMENSION, texture_pkg.DIMENSION, data),
    );

    var width: c_int = 0;
    var height: c_int = 0;
    var nrChannels: c_int = 0;
    const image = stb.stbi_load("assets/texture_earth.png", &width, &height, &nrChannels, 3);
    defer stb.stbi_image_free(image);

    var width_u: usize = @intCast(width);
    var height_u: usize = @intCast(height);

    var raw_slice = image[0 .. width_u * height_u * 3];
    const rgba_slice: []const [3]u8 = @ptrCast(@alignCast(raw_slice));

    var rootNode = try pool.create(Node.init(null, null));

    const earthT = TextureData{ .rgb = rgba_slice };
    const earthTexture = texturePool.create(
        Texture.init(width_u, height_u, earthT),
    );

    const sun_image = stb.stbi_load("assets/sun_texture.jpg", &width, &height, &nrChannels, 3);
    defer stb.stbi_image_free(sun_image);
    std.debug.assert(sun_image != null);

    width_u = @intCast(width);
    height_u = @intCast(height);

    raw_slice = sun_image[0 .. width_u * height_u * 3];
    const sun_rgba_slice: []const [3]u8 = @ptrCast(@alignCast(raw_slice));

    const sunT = TextureData{ .rgb = sun_rgba_slice };
    const sunTexture = texturePool.create(
        Texture.init(width_u, height_u, sunT),
    );

    const moon_image = stb.stbi_load("assets/moon_texture.jpg", &width, &height, &nrChannels, 3);
    defer stb.stbi_image_free(moon_image);
    std.debug.assert(moon_image != null);
    std.debug.assert(nrChannels == 3);

    width_u = @intCast(width);
    height_u = @intCast(height);

    raw_slice = moon_image[0 .. width_u * height_u * 3];
    const moon_rgba_slice: []const [3]u8 = @ptrCast(@alignCast(raw_slice));

    const moonT = TextureData{ .rgb = moon_rgba_slice };
    const moonTexture = texturePool.create(
        Texture.init(width_u, height_u, moonT),
    );

    scene.addTexture(starTexture);
    scene.addTexture(earthTexture);
    scene.addTexture(sunTexture);
    scene.addTexture(moonTexture);

    std.debug.print("w: {}, h: {}, :nrChannels: {}\n", .{ width, height, nrChannels });
    var random = std.Random.DefaultPrng.init(0);
    const rand = random.random();

    var stars = std.ArrayList(NodeHandle).empty;
    defer stars.deinit(allocator);
    for (0..500) |_| {
        const perimeter = 20;
        const x = rand.float(f32) * perimeter - perimeter / 2;
        const y = rand.float(f32) * perimeter - perimeter / 2;
        const z = rand.float(f32) * perimeter - perimeter / 2;

        const rx = rand.float(f32) * std.math.pi;
        const ry = rand.float(f32) * std.math.pi;
        const rz = rand.float(f32) * std.math.pi;

        const starGeo = try Geometry.makeTriangle(allocator, 0, 0, 0);
        const starNode = try pool.create(Node.init(starGeo, starTexture));
        starNode.get().transform.rotateX(rx);
        starNode.get().transform.rotateX(ry);
        starNode.get().transform.rotateX(rz);
        starNode.get().transform.translate(x, y, z);
        starNode.get().transform.scale(0.04);
        starNode.get().geometry.?.setBaseColor(.{ 0, 0, 0 });

        try stars.append(allocator, starNode);
        try rootNode.get().addChild(allocator, starNode);
    }

    var sunNode = try pool.create(Node.init(sphereGeo, sunTexture));
    sunNode.get().transform.translate(0, 0, 0.0);

    try rootNode.get().addChild(allocator, sunNode);
    try scene.addRoot(rootNode);

    var camera = Camera.init(math.pi / 4.0, 640.0 / 420.0, 0.01, 100);
    camera.lookAt(.{ 0, 25, 0 }, .{ 0.1, 0.1, 0.1 }, .{ 0.0, 1.0, 0.0 });

    var earthNode = try pool.create(Node.init(earthGeo, earthTexture));
    earthNode.get().transform.translate(6, 0, 0);
    earthNode.get().transform.scale(2);
    earthNode.get().geometry.?.setBaseColor(.{ 0, 0, 0 });
    earthNode.get().transform.scale(0.3);

    var moonGeo = try sphereGeo.clone(allocator);
    moonGeo.setBaseColor(.{ 0.0, 0.0, 0.0 });
    const moonNode = try pool.create(Node.init(moonGeo, moonTexture));
    moonNode.get().transform.scale(0.3);
    moonNode.get().transform.translate(1.5, 0, 0);
    try earthNode.get().addChild(allocator, moonNode);

    try sunNode.get().addChild(allocator, earthNode);

    var lightPool = LightPool.init(allocator);
    defer lightPool.deinit();

    var light = try lightPool.create(Light.init(&.{ 0, 0, 0 }, 2.0));
    light.get().color.ambient = .{ 1, 1, 1 };
    light.get().color.diffuse = .{ 0.3, 0.3, 0.3 };
    light.get().color.specular = .{ 0.874, 0.192, 0.34 };
    light.get().constant = 0.4;

    light.get().node = earthNode;
    scene.addLight(light);

    const window = glfw.glfwGetCurrentContext();

    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    while (glfw.glfwWindowShouldClose(window) == 0) {
        try app.render(arena_allocator, &scene, &camera);
        _ = arena.reset(.retain_capacity);

        sunNode.get().transform.rotateY(0.04);
        earthNode.get().transform.rotateY(0.06);
        updateStars(stars, rand);

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

fn updateStars(stars: std.ArrayList(NodeHandle), rand: Random) void {
    for (stars.items) |star| {
        if (rand.float(f32) < 0.65) {
            const range = 0.05;
            const tx = rand.float(f32) * range - range / 2.0;
            const ty = rand.float(f32) * range - range / 2.0;
            const tz = rand.float(f32) * range - range / 2.0;
            star.get().transform.translate(tx, ty, tz);

            const rx = rand.float(f32) * 2 - 1;
            const ry = rand.float(f32) * 2 - 1;
            const rz = rand.float(f32) * 2 - 1;
            star.get().transform.rotateX(rx);
            star.get().transform.rotateX(ry);
            star.get().transform.rotateX(rz);
        }
    }
}
