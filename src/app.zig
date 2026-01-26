const std = @import("std");
const Allocator = std.mem.Allocator;

const Scene = @import("scene.zig").Scene;
const Vertex = @import("scene.zig").Vertex;
const Camera = @import("camera.zig").Camera;

const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const gl = @cImport(@cInclude("gl.h"));
/// A callback function for handling C-style errors from GLFW.
/// Follows the C calling convention to ensure compatibility with external libraries.
fn error_callback(err_code: c_int, description: [*c]const u8) callconv(.c) void {
    std.debug.print("Error [{d}]: {s}\n", .{ err_code, description });
}

/// Failures related to the display lifecycle, from initialisation to rendering.
pub const GraphicsError = error{
    // Initialisation errors
    InitFailed,
    WindowCreationFailed,
    MakeContextFailed,
    LoadGLFailed,
    GlCompilationFailed,
};

pub const App = struct {
    const Self = @This();

    window: *glfw.struct_GLFWwindow,
    program: gl.GLuint,

    /// Initializes GLFW, creates a window, and loads OpenGL function pointers.
    /// Caller must call 'deinit' on success to free resources.
    pub fn init(title: [*]const u8, width: c_int, height: c_int) GraphicsError!App {
        _ = glfw.glfwSetErrorCallback(error_callback);

        if (glfw.glfwInit() == 0) {
            return GraphicsError.InitFailed;
        }
        errdefer glfw.glfwTerminate();

        const window = glfw.glfwCreateWindow(width, height, title, null, null) orelse {
            return GraphicsError.WindowCreationFailed;
        };
        errdefer glfw.glfwDestroyWindow(window);

        glfw.glfwMakeContextCurrent(window);
        if (glfw.glfwGetCurrentContext() == null) {
            return GraphicsError.MakeContextFailed;
        }

        if (gl.gladLoadGL(glfw.glfwGetProcAddress) == 0) {
            return error.LoadGLFailed;
        }
        glfw.glfwSwapInterval(1);

        gl.glEnable(gl.GL_DEPTH_TEST);

        const program = try compile();

        return .{
            .window = window,
            .program = program,
        };
    }

    fn compile() !gl.GLuint {
        const vertex_shader_raw = @embedFile("shaders/vertex.shader");
        const fragment_shader_raw = @embedFile("shaders/fragment.shader");

        // wrap in array of C string pointers for glShaderSource
        const vertex_shader_text: [1][*c]const u8 = .{vertex_shader_raw.ptr};
        const fragment_shader_text: [1][*c]const u8 = .{fragment_shader_raw.ptr};

        const vertex_shader = gl.glCreateShader(gl.GL_VERTEX_SHADER);
        gl.glShaderSource(vertex_shader, 1, &vertex_shader_text, null);
        gl.glCompileShader(vertex_shader);
        defer gl.glDeleteShader(vertex_shader);

        const fragment_shader = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
        gl.glShaderSource(fragment_shader, 1, &fragment_shader_text, null);
        gl.glCompileShader(fragment_shader);
        defer gl.glDeleteShader(fragment_shader);

        const program: gl.GLuint = gl.glCreateProgram();
        gl.glAttachShader(program, vertex_shader);
        gl.glAttachShader(program, fragment_shader);
        gl.glLinkProgram(program);

        if (gl.glGetError() != gl.GL_NO_ERROR) {
            return GraphicsError.GlCompilationFailed;
        }

        return program;
    }

    /// Cleans up all resources associated with the application.
    pub fn deinit(self: Self) void {
        glfw.glfwDestroyWindow(self.window);
        glfw.glfwTerminate();
    }

    /// TODO
    pub fn render(
        self: *Self,
        allocator: Allocator,
        scene: *Scene,
        camera: *const Camera,
    ) !void {
        var vertices = std.ArrayList(Vertex).empty;
        defer vertices.deinit(allocator);
        try scene.generateVertices(allocator, &vertices);

        var vertex_buffer: gl.GLuint = 0;
        gl.glGenBuffers(1, &vertex_buffer);
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vertex_buffer);
        gl.glBufferData(
            gl.GL_ARRAY_BUFFER,
            @sizeOf(Vertex) * @as(c_long, @intCast(vertices.items.len)),
            vertices.items.ptr,
            gl.GL_STATIC_DRAW,
        );
        const vpos_location: c_uint = @intCast(gl.glGetAttribLocation(
            self.program,
            "vPos",
        ));
        const vcol_location: c_uint = @intCast(gl.glGetAttribLocation(
            self.program,
            "vCol",
        ));

        const proj_location: c_uint = @intCast(gl.glGetUniformLocation(
            self.program,
            "proj",
        ));

        const view_location: c_uint = @intCast(gl.glGetUniformLocation(
            self.program,
            "view",
        ));

        // _ = camera;
        // _ = proj_location;
        // _ = view_location;

       // std.debug.print("v pos: {}, v col {}\n", .{ vpos_location, vcol_location });

        var vertex_array: gl.GLuint = 0;
        gl.glGenVertexArrays(1, &vertex_array);
        gl.glBindVertexArray(vertex_array);
        gl.glEnableVertexAttribArray(vpos_location);
        gl.glVertexAttribPointer(
            vpos_location,
            3,
            gl.GL_FLOAT,
            gl.GL_FALSE,
            @sizeOf(Vertex),
            @ptrFromInt(@offsetOf(Vertex, "position")),
        );

        gl.glEnableVertexAttribArray(vcol_location);
        gl.glVertexAttribPointer(
            vcol_location,
            3,
            gl.GL_FLOAT,
            gl.GL_FALSE,
            @sizeOf(Vertex),
            @ptrFromInt(@offsetOf(Vertex, "color")),
        );

        var width: i32 = 0;
        var height: i32 = 0;
        glfw.glfwGetFramebufferSize(self.window, &width, &height);
        const ratio: f32 = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
        gl.glViewport(0, 0, width, height);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
        gl.glUseProgram(self.program);

        gl.glUniformMatrix4fv(@intCast(proj_location), 1, gl.GL_FALSE, @ptrCast(&camera.projection.mat));
        gl.glUniformMatrix4fv(@intCast(view_location), 1, gl.GL_FALSE, @ptrCast(&camera.view.mat));

        // const view: [4][4]f32 = .{
        //     .{1, 0, 0, 0},
        //     .{0   , 1, 0, 0},
        //     .{0   , 0, 0, -1},
        //     .{0   , 0, -1, 0},
        // };
        // _ = camera;
        // gl.glUniformMatrix4fv(@intCast(proj_location), 1, gl.GL_FALSE, @ptrCast(&view));
         

        gl.glBindVertexArray(vertex_array);
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, @as(c_int, @intCast(vertices.items.len)));

        glfw.glfwSwapBuffers(self.window);
        glfw.glfwPollEvents();
        _ = ratio;
        //

        // for (vertices.items) |vertex| {
        //     std.debug.print("vertex: {any}\n", .{vertex});
        // }
    }
};
