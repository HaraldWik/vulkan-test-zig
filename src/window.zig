const std = @import("std");
const sdl = @import("sdl");
const vk = @import("vulkan");

extern "SDL3" fn SDL_Vulkan_CreateSurface(window: ?*sdl.SDL_Window, instance: vk.VkInstance, allocator: ?*const vk.VkAllocationCallbacks, surface: *vk.VkSurfaceKHR) callconv(.c) bool;

pub const Window = opaque {
    pub inline fn toC(self: *@This()) ?*sdl.SDL_Window {
        return @ptrCast(@alignCast(self));
    }

    pub fn init(title: [*:0]const u8, width: usize, height: usize) !*@This() {
        if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
            std.log.err("Failed init SDL3: {s}", .{sdl.SDL_GetError()});
            return error.SdlInit;
        }

        const window = sdl.SDL_CreateWindow(title, @intCast(width), @intCast(height), sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_VULKAN) orelse {
            std.log.err("Failed to create window: {s}", .{sdl.SDL_GetError()});
            sdl.SDL_Quit();
            return error.SdlCreateWindow;
        };

        return @ptrCast(window);
    }

    pub fn deinit(self: *@This()) void {
        sdl.SDL_DestroyWindow(self.toC());
        sdl.SDL_Quit();
    }

    pub fn shouldClose(_: *@This()) bool {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            switch (event.type) {
                sdl.SDL_EVENT_QUIT, sdl.SDL_EVENT_TERMINATING => return true,
                else => break,
            }
        }
        return false;
    }

    pub fn getSize(self: *@This()) !struct { usize, usize } {
        var size: struct { c_int, c_int } = undefined;
        if (!sdl.SDL_GetWindowSize(self.toC(), &size.@"0", &size.@"1")) {
            std.log.err("Failed to get window size: {s}", .{sdl.SDL_GetError()});
            return error.SdlGetWindowSize;
        }
        return .{ @intCast(size.@"0"), @intCast(size.@"1") };
    }

    pub fn getVulkanInstanceExtensions(_: *@This()) [][*:0]const u8 {
        var count: u32 = 0;
        var extensions = sdl.SDL_Vulkan_GetInstanceExtensions(&count);
        return @ptrCast(@constCast(extensions[0..count]));
    }

    pub fn initVulkanSurface(self: *anyopaque, instance: *anyopaque) !*anyopaque {
        var surface: ?*anyopaque = undefined;
        if (!SDL_Vulkan_CreateSurface(@ptrCast(self), @ptrCast(instance), null, &surface)) {
            std.log.err("Failed to create vulkan surface in SDL3: {s}", .{sdl.SDL_GetError()});
            return error.SdlVulkanCreateSurface;
        }
        return surface orelse return error.SdlVulkanCreateSurface;
    }
};
