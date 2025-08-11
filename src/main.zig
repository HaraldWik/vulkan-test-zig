const std = @import("std");
const engine = @import("engine");

pub fn main() !void {
    const window: *engine.Window = try .init("Window", 900, 800);
    defer window.deinit();

    const ctx: engine.gfx.Context = try .init();
    defer ctx.deinit();

    while (!window.shouldClose()) {}
}
