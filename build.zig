const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("Stage", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "Stage", .module = mod },
        },
    });

    const exe = b.addExecutable(.{
        .name = "Stage",
        .root_module = exe_mod,
    });

    exe.addIncludePath(b.path("src/c/"));
    exe.addCSourceFile(.{
        .file = b.path("src/c/gl.c"),
        .flags = &.{},
    });
    exe.linkLibC();
    exe.linkSystemLibrary("glfw");

    b.installArtifact(exe);

    const exe_check = b.addExecutable(.{
        .name = "check",
        .root_module = exe_mod,
    });

    const check = b.step("check", "Check if Stage compiles");
    check.dependOn(&exe_check.step);
    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .name = "test",
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    // b.installArtifact(exe_tests);
    b.installArtifact(mod_tests);
}
