const std = @import("std");
const vk = @import("vulkan.zig");

instance: *vk.Instance,
debug_messenger: *vk.DebugMessenger,
surface: *vk.Surface,

pub const Config = struct {
    instance: struct {
        extensions: ?[]const [*:0]const u8 = null,
        layers: ?[]const [*:0]const u8 = null,
    } = .{},
    device: struct {
        extensions: ?[]const [*:0]const u8 = null,
    } = .{},
    surface: struct {
        data: ?*anyopaque = null,
        init: ?*const fn (*anyopaque, *anyopaque) anyerror!*anyopaque = null,
    } = .{},
};

pub fn init(config: Config) !@This() {
    const instance: *vk.Instance = try .init(config.instance.extensions, config.instance.layers);
    const debug_messenger: *vk.DebugMessenger = try .init(instance);
    const surface: *vk.Surface = if (config.surface.init != null and config.surface.data != null) @ptrCast(try config.surface.init.?(config.surface.data.?, instance)) else try vk.Surface.init(instance);

    return .{ .instance = instance, .debug_messenger = debug_messenger, .surface = surface };
}

pub fn deinit(self: @This()) void {
    self.surface.deinit(self.instance);
    self.debug_messenger.deinit(self.instance);
    self.instance.deinit();
}
