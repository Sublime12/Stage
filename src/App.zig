const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const gl = @cImport(@cInclude("gl.h"));
const std = @import("std");
const Scene = @import("Scene.zig").Scene;
const Vertex = @import("Scene.zig").Vertex;
const Allocator = std.mem.Allocator;
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
};

pub const App = struct {
    const Self = @This();

    window: *glfw.struct_GLFWwindow,

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

        return .{
            .window = window,
        };
    }

    /// Cleans up all resources associated with the application.
    pub fn deinit(self: Self) void {
        glfw.glfwDestroyWindow(self.window);
        glfw.glfwTerminate();
    }

    /// TODO
    pub fn render(self: *Self, allocator: Allocator, scene: *Scene) !void {
        _ = self;
        var vertices = std.ArrayList(Vertex).empty;
        defer vertices.deinit(allocator);
        try scene.generateVertices(allocator, &vertices);

        std.debug.print("vertices: {any}", .{vertices.items});
    }
};
