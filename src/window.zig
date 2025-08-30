const std = @import("std");
const wio = @import("wio");

pub fn init(config: wio.CreateWindowOptions) !*@This() {
    const window: wio.Window = try wio.createWindow(config);
}

pub fn deinit(self: *@This()) void {}

pub fn shouldClose(_: *@This()) bool {
    return false;
}

pub fn getSize(self: *@This()) !struct { usize, usize } {}

pub fn getVulkanInstanceExtensions(_: *@This()) []const [*:0]const u8 {}

pub fn initVulkanSurface(self: *anyopaque, instance: *anyopaque) !*anyopaque {
    var surface: u64 = undefined;
    selfs.createSurface(@intFromPtr(instance), null, &surface);
}
