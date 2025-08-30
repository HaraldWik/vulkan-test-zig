const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sdl = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        .lto = optimize != .Debug,
        .preferred_linkage = .dynamic,
    });

    const sdl_c = b.addTranslateC(.{
        .root_source_file = sdl.path("include/SDL3/SDL.h"),
        .target = target,
        .optimize = optimize,
    });
    sdl_c.addIncludePath(sdl.path("include"));

    const vulkan = b.addTranslateC(.{
        .root_source_file = b.dependency("vulkan_headers", .{}).path("include/vulkan/vulkan.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    }).createModule();
    vulkan.linkSystemLibrary("vulkan", .{});

    const mod = b.addModule("engine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "sdl", .module = sdl_c.createModule() },
            .{ .name = "vulkan", .module = vulkan },
        },
    });
    mod.linkSystemLibrary("SDL3", .{});

    const exe = b.addExecutable(.{
        .name = "engine",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "engine", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
