const std = @import("std");
const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});

const gl = @cImport(@cInclude("gl.h"));
const cmath = @cImport(@cInclude("linmath.h"));
const math = std.math;

const Stage = @import("App.zig");
const App = Stage.App;
const Scene = @import("Scene.zig").Scene;
const Geometry = @import("Scene.zig").Geometry;
const Node = @import("Scene.zig").Node;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try App.init("Stage window", 640, 480);
    defer app.deinit();

    var scene = Scene.init(allocator);
    defer scene.deinit();

    const triangleGeo = try Geometry.makeTriangle(allocator, 0, 0, 0);
    var triangleNode = Node.init(triangleGeo);

    const triangleGeo2 = try Geometry.makeTriangle(allocator, -0.2, -0.2, 0);
    var triangleNode2 = Node.init(triangleGeo2);
    const node2 = try triangleNode.addChild(allocator, &triangleNode2);

    const triangleGeo3 = try Geometry.makeTriangle(allocator, -0.4, -0.4, 0);
    const triangleNode3 = Node.init(triangleGeo3);
    _ = try triangleNode.addChild(allocator, &triangleNode3);

    const triangleGeo4 = try Geometry.makeTriangle(allocator, -0.6, -0.6, 0);
    const triangleNode4 = Node.init(triangleGeo4);
    _ = try node2.get().addChild(allocator, &triangleNode4);

    // const triangleGeo3 = try Geometry.makeTriangle(allocator, -0.4, -0.4, 0);
    // const triangleNode3 = Node.init(triangleGeo3);
    // try triangleNode.addChild(allocator, &triangleNode3);

    std.debug.print("node tree: {any}\n", .{triangleNode});

    try scene.addNode(&triangleNode);

    try app.render(allocator, &scene);

    std.Thread.sleep(std.time.ns_per_s * 2);
    // const earthGeometry = Geometry.Sphere();
    // const earth = Node.init(earthGeometry, gpa);
    // scene.addNode(earth);

    // const luneGeo = Geometry.Sphere();
    // const lune = Node.init(luneGeo);

    // earth.addNode(lune, alloc);

    // app.render(scene);
}

// const vertex_shader_raw = @embedFile("shaders/vertex.shader");
// const fragment_shader_raw = @embedFile("shaders/fragment.shader");
//
// // wrap in array of C string pointers for glShaderSource
// const vertex_shader_text: [1][*c]const u8 = .{ vertex_shader_raw.ptr };
// const fragment_shader_text: [1][*c]const u8 = .{ fragment_shader_raw.ptr };
//
// const Vertex = extern struct {
//     pos: [3]f32,
//     col: [3]f32,
// };
//
// const vertices: [6]Vertex = .{
//     .{ .pos = .{  0.0,  0.6, 0.2 }, .col = .{ 0.0, 0.0, 1.0 } },
//     .{ .pos = .{  0.6, -0.4, 0.4 }, .col = .{ 0.0, 1.0, 0.0 } },
//     .{ .pos = .{ -0.6, -0.4, 0.7 }, .col = .{ 1.0, 0.0, 0.0 } },
//     .{ .pos = .{  0.3,  0.7, 0.5 }, .col = .{ 0.5, 0.5, 1.0 } },
//     .{ .pos = .{  -0.3, -0.0, -0.4 }, .col = .{ 0.9, 0.0, 0.2 } },
//     .{ .pos = .{ 0.6, -0.4, -0.7 }, .col = .{ 0.0, 0.9, 0.4 } },
// };
//
//
// fn error_callback(err: c_int, description: [*c]const u8) callconv(.c) void {
//     _ = err;
//     _ = c.fprintf(c.stderr, "Error: %s\n", description);
// }
// pub fn main() !void {
//     _ = glfw.glfwSetErrorCallback(error_callback);
//
//     if (glfw.glfwInit() == 0) {
//         c.exit(c.EXIT_FAILURE);
//     }
//
//     const window = glfw.glfwCreateWindow(640, 480, "OpenGl Triangle", null, null);
//     if (window == null) {
//         glfw.glfwTerminate();
//         c.exit(c.EXIT_FAILURE);
//     }
//
//     glfw.glfwMakeContextCurrent(window);
//     _ = gl.gladLoadGL(glfw.glfwGetProcAddress);
//     glfw.glfwSwapInterval(1);
//
//     var vertex_buffer: gl.GLuint = 0;
//     gl.glGenBuffers(1, &vertex_buffer);
//     gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vertex_buffer);
//     gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);
//
//     const vertex_shader = gl.glCreateShader(gl.GL_VERTEX_SHADER);
//     gl.glShaderSource(vertex_shader, 1, &vertex_shader_text, null);
//     gl.glCompileShader(vertex_shader);
//
//     const fragment_shader = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
//     gl.glShaderSource(fragment_shader, 1, &fragment_shader_text, null);
//     gl.glCompileShader(fragment_shader);
//
//     const program: gl.GLuint = gl.glCreateProgram();
//     gl.glAttachShader(program, vertex_shader);
//     gl.glAttachShader(program, fragment_shader);
//     gl.glLinkProgram(program);
//
//     // std.debug.print("shader text: {s}\n fragment shader: {s}\n",
//     //     .{ vertex_shader_text[0], fragment_shader_text[0] });
//     const vpos_location: c_uint = @intCast(gl.glGetAttribLocation(program, "vPos"));
//     const vcol_location: c_uint = @intCast(gl.glGetAttribLocation(program, "vCol"));
//     const mvp_location: c_int = @intCast(gl.glGetUniformLocation(program, "MVP"));
//
//     var vertex_array: gl.GLuint = 0;
//     gl.glGenVertexArrays(1, &vertex_array);
//     gl.glBindVertexArray(vertex_array);
//     gl.glEnableVertexAttribArray(vpos_location);
//     gl.glVertexAttribPointer(vpos_location, 3, gl.GL_FLOAT, gl.GL_FALSE,
//         @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "pos")),
//     );
//
//     gl.glEnableVertexAttribArray(vcol_location);
//     gl.glVertexAttribPointer(vcol_location, 3, gl.GL_FLOAT, gl.GL_FALSE,
//         @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "col")),
//     );
//     var mvp: [4][4]f32 = .{
//         .{ 1, 0, 0, 0 },
//         .{ 0, 1, 0, 0 },
//         .{ 0, 0, 1, 0 },
//         .{ 0, 0, 0, 1 },
//     };
//
//     while (glfw.glfwWindowShouldClose(window) == 0) {
//         var width: i32 = 0;
//         var height: i32 = 0;
//         glfw.glfwGetFramebufferSize(window, &width, &height);
//         const ratio: f32 = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
//         gl.glViewport(0, 0, width, height);
//         gl.glClear(gl.GL_COLOR_BUFFER_BIT);
//
//         const cos = math.cos(math.pi / 90.0);
//         const sin = math.sin(math.pi / 90.0);
//          const rz: [4][4]f32 = .{
//             .{ cos, -sin, 0, 0 },
//             .{ sin,  cos, 0, 0 },
//             .{   0,    0, 1, 0 },
//             .{   0,    0, 0, 1 },
//         };
//         const rx: [4][4]f32 = .{
//             .{   1,   0,    0, 0 },
//             .{   0, cos, -sin, 0 },
//             .{   0, sin,  cos, 0 },
//             .{   0,   0,    0, 1 },
//         };
//         // _ = rz;
//         _ = rx;
//         var tx: [4][4]f32 = .{
//             .{   1,   0,    0, 0 },
//             .{   0,   1,    0, 0 },
//             .{   0,   0,    1, 0 },
//             .{   0,   0.03, 0, 1 },
//         };
//
//         var rt: [4][4]f32 = undefined;
//         cmath.mat4x4_mul(&rt, &rz, &tx);
//         // cmath.mat4x4_transpose(tx, tx);
//         // _ = tx;
//
//         cmath.mat4x4_mul(&mvp, &mvp, &rt);
//         //    [ cos(θ)  -sin(θ)   0   0 ]
//         //    [ sin(θ)   cos(θ)   0   0 ]
//         //    [   0        0      1   0 ]
//         //    [   0        0      0   1 ]
//         // cmath.mat4x4_rotate_Z(&mvp, &mvp, 0.001);
//
//         for (mvp) |row| {
//             for (row) |el| {
//                 std.debug.print("{} ", .{el});
//             }
//             std.debug.print("\n", .{});
//         }
//
//         gl.glUseProgram(program);
//         gl.glUniformMatrix4fv(mvp_location, 1, gl.GL_FALSE, @ptrCast(&mvp));
//         gl.glBindVertexArray(vertex_array);
//         gl.glDrawArrays(gl.GL_TRIANGLES, 0, 6);
//
//         glfw.glfwSwapBuffers(window);
//         glfw.glfwPollEvents();
//         _ = ratio;
//     }
//
//     glfw.glfwDestroyWindow(window);
//     glfw.glfwTerminate();
// }
