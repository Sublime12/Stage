const std = @import("std");
// const renderer = @import("_3DRenderer");
const glfw = @cImport(
    @cInclude("GLFW/glfw3.h")
);
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});

const gl = @cImport(
    @cInclude("gl.h")
);

const vertex_shader_raw = @embedFile("vertex.shader");
const fragment_shader_raw = @embedFile("fragment.shader");

// wrap in array of C string pointers for glShaderSource
const vertex_shader_text: [1][*c]const u8 = .{ vertex_shader_raw.ptr };
const fragment_shader_text: [1][*c]const u8 = .{ fragment_shader_raw.ptr };

const Vertex = extern struct {
    pos: [2]f32,
    col: [3]f32,
};

const vertices: [3]Vertex = .{
    .{ .pos = .{ -0.6, -0.4 }, .col = .{ 1.0, 0.0, 0.0 } },
    .{ .pos = .{  0.6, -0.4 }, .col = .{ 0.0, 1.0, 0.0 } },
    .{ .pos = .{  0.0,  0.6 }, .col = .{ 0.0, 0.0, 1.0 } },
};

fn error_callback(err: c_int, description: [*c]const u8) callconv(.c) void {
    _ = err;
    _ = c.fprintf(c.stderr, "Error: %s\n", description);
}


pub fn main() !void {
    _ = glfw.glfwSetErrorCallback(error_callback);

    if (glfw.glfwInit() == 0) {
        c.exit(c.EXIT_FAILURE);
    }

    const window = glfw.glfwCreateWindow(640, 480, "OpenGl Triangle", null, null);
    if (window == null) {
        glfw.glfwTerminate();
        c.exit(c.EXIT_FAILURE);
    }
    
    // glfw.glfwSetKeyCallback(window, key_callback);
    glfw.glfwMakeContextCurrent(window);
    _ = gl.gladLoadGL(glfw.glfwGetProcAddress);
    glfw.glfwSwapInterval(1);

    var vertex_buffer: gl.GLuint = 0;
    gl.glGenBuffers(1, &vertex_buffer);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vertex_buffer);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);

    const vertex_shader = gl.glCreateShader(gl.GL_VERTEX_SHADER);
    gl.glShaderSource(vertex_shader, 1, &vertex_shader_text, null);
    gl.glCompileShader(vertex_shader);

    const fragment_shader = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
    gl.glShaderSource(fragment_shader, 1, &fragment_shader_text, null);
    gl.glCompileShader(fragment_shader);

    const program = gl.glCreateProgram();
    gl.glAttachShader(program, vertex_shader);
    gl.glAttachShader(program, fragment_shader);
    gl.glLinkProgram(program);

    while (true) {}

    while (glfw.glfwWindowShouldClose(window) != 0) {
        var width: i32 = 0;
        var height: i32 = 0;
        glfw.glfwGetFramebufferSize(window, &width, &height);
        const ratio: f32 = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
        gl.glViewport(0, 0, width, height);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);
        _ = ratio;
    }
}
