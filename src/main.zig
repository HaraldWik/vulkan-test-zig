const std = @import("std");
const builtin = @import("builtin");
const engine = @import("engine");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const window: *engine.Window = try .init(allocator, "Window", 900, 800);
    defer window.deinit();

    const ctx: engine.gfx.Context = try .init(engine.gfx.Context.Config{
        .instance = .{
            .extensions = &.{
                "VK_KHR_surface",
                switch (builtin.target.os.tag) {
                    .windows => "VK_KHR_win32_surface",
                    .linux, .freebsd, .openbsd, .dragonfly => "VK_KHR_wayland_surface",
                    .macos => "VK_MVK_macos_surface",
                    else => @compileError("Unsupported OS"),
                },
                "VK_EXT_debug_utils",
            },
            .layers = &.{"VK_LAYER_KHRONOS_validation"},
        },
        .device = .{
            .extensions = &.{"VK_KHR_swapchain"},
        },
        .surface = .{
            .data = window,
            .init = engine.Window.initVulkanSurface,
        },
    });
    defer ctx.deinit();

    while (!window.shouldClose()) {}
}
