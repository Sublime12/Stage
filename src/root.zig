//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

pub const App = @import("app.zig");

pub const math = @import("math.zig");
pub const scene = @import("scene.zig");
pub const node = @import("node.zig");

test {
    std.testing.refAllDecls(@This());
}
