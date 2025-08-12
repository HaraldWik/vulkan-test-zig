const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const sdl = b.dependency("sdl", .{
    //     .target = target,
    //     .optimize = optimize,
    //     .lto = optimize != .Debug,
    //     .preferred_linkage = .dynamic,
    // });

    // const sdl_translate_c = b.addTranslateC(.{
    //     .root_source_file = sdl.path("include/SDL3/SDL.h"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // sdl_translate_c.addIncludePath(sdl.path("include"));
    // const c_mod = sdl_translate_c.createModule();
    // c_mod.addIncludePath(sdl.path("include/"));

    const c_mod = b.addModule("c", .{
        .root_source_file = b.addWriteFiles().add("c.zig",
            \\pub const c = @cImport({
            \\  @cInclude("SDL3/SDL.h");
            \\  @cInclude("SDL3/SDL_vulkan.h");
            \\});
        ),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    c_mod.linkSystemLibrary("SDL3", .{});

    const wgpu_mod = b.dependency("wgpu_native_zig", .{}).module("wgpu");

    const mod = b.addModule("engine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "wgpu", .module = wgpu_mod },
            .{ .name = "c", .module = c_mod },
        },
    });
    mod.linkSystemLibrary("vulkan", .{});

    const exe = b.addExecutable(.{
        .name = "engine",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "engine", .module = mod },
                .{ .name = "c", .module = c_mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

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
