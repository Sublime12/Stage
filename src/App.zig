const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const gl = @cImport(@cInclude("gl.h"));
const std = @import("std");

fn error_callback(err: c_int, description: [*c]const u8) callconv(.c) void {
    std.debug.print("Errors: num {} -> {s}", .{ err, description });
}

pub const GlfwError = error{
    InitFailed,
    WindowCreationFailed,
    MakeContextFailed,
    LoadGLFailed,
};

pub const App = struct {
    window: *glfw.struct_GLFWwindow,

    pub fn init(title: [*]const u8, width: c_int, height: c_int) GlfwError!App {
        _ = glfw.glfwSetErrorCallback(error_callback);

        if (glfw.glfwInit() == 0) {
            return GlfwError.InitFailed;
        }
        errdefer glfw.glfwTerminate();

        const window = glfw.glfwCreateWindow(width, height, title, null, null) orelse {
            return GlfwError.WindowCreationFailed;
        };
        errdefer glfw.glfwDestroyWindow(window);

        glfw.glfwMakeContextCurrent(window);
        if (glfw.glfwGetCurrentContext() == null) {
            return GlfwError.MakeContextFailed;
        }

        if (gl.gladLoadGL(glfw.glfwGetProcAddress) == 0) {
            return error.LoadGLFailed;
        }
        glfw.glfwSwapInterval(1);

        return .{
            .window = window,
        };
    }

    pub fn deinit(self: @This()) void {
        glfw.glfwDestroyWindow(self.window);
        glfw.glfwTerminate();
    }

    pub fn render() void {}
};
