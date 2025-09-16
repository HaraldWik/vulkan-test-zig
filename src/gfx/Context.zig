const std = @import("std");
const vk = @import("vulkan.zig");

instance: vk.Instance,
debug_messenger: vk.DebugMessenger,
surface: vk.Surface,
physical_device: vk.PhysicalDevice,
device: vk.Device,

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
    const instance: vk.Instance = try .init(config.instance.extensions, config.instance.layers);
    const debug_messenger: vk.DebugMessenger = try .init(instance, .{});
    const surface: vk.Surface = if (config.surface.init != null and config.surface.data != null) @ptrCast(try config.surface.init.?(config.surface.data.?, instance)) else @panic("not supported");
    var queue_family_index: u32 = undefined;
    const physical_device: vk.PhysicalDevice = try .init(instance, surface, &queue_family_index);
    const device: vk.Device = try .init(physical_device, queue_family_index, config.device.extensions);

    return .{
        .instance = instance,
        .debug_messenger = debug_messenger,
        .surface = surface,
        .physical_device = physical_device,
        .device = device,
    };
}

pub fn deinit(self: @This()) void {
    self.device.deinit();
    self.surface.deinit(self.instance);
    self.debug_messenger.deinit(self.instance);
    self.instance.deinit();
}
