pub const vk = @import("vulan");
pub const wio = @import("wio");

pub const Window = @import("window.zig").Window;
pub const gfx = struct {
    pub const vk = @import("gfx/vulkan.zig");
    pub const Context = @import("gfx/Context.zig");
};
