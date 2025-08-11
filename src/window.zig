const std = @import("std");
const c = @import("c").c;

pub const Window = opaque {
    const Self = @This();

    pub inline fn toC(self: *Self) ?*c.SDL_Window {
        return @ptrCast(@alignCast(self));
    }

    pub fn init(title: [*:0]const u8, width: usize, height: usize) !*Self {
        if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
            std.log.err("Failed init SDL3: {s}", .{c.SDL_GetError()});
            return error.SdlInit;
        }

        const window = c.SDL_CreateWindow(title, @intCast(width), @intCast(height), c.SDL_WINDOW_RESIZABLE) orelse {
            std.log.err("Failed to create window: {s}", .{c.SDL_GetError()});
            c.SDL_Quit();
            return error.SdlCreateWindow;
        };

        return @ptrCast(window);
    }

    pub fn deinit(self: *Self) void {
        c.SDL_DestroyWindow(self.toC());
        c.SDL_Quit();
    }

    pub fn shouldClose(_: *Self) bool {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT, c.SDL_EVENT_TERMINATING => return true,
                else => break,
            }
        }
        return false;
    }

    pub fn getNative(self: *Self) void {
        const props = c.SDL_GetWindowProperties(self.toC());
        if (props == 0) {
            std.log.err("Failed to get window properties: {s}", .{c.SDL_GetError()});
            return error.SdlGetWindowProperties;
        }
    }

    pub fn getSize(self: *Self) !struct { usize, usize } {
        var size: struct { c_int, c_int } = undefined;
        if (!c.SDL_GetWindowSize(self.toC(), &size.@"0", &size.@"1")) {
            std.log.err("Failed to get window size: {s}", .{c.SDL_GetError()});
            return error.SdlGetWindowSize;
        }
        return .{ @intCast(size.@"0"), @intCast(size.@"1") };
    }
};
