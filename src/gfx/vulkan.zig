const std = @import("std");
pub const c = @import("vulkan");

pub fn vkCheck(result: c.VkResult) !void {
    if (result != c.VK_SUCCESS) return switch (result) {
        c.VK_ERROR_OUT_OF_HOST_MEMORY => error.OutOfHostMemory,
        c.VK_ERROR_OUT_OF_DEVICE_MEMORY => error.OutOfDeviceMemory,
        c.VK_ERROR_INITIALIZATION_FAILED => error.InitializationFailed,
        c.VK_ERROR_DEVICE_LOST => error.DeviceLost,
        c.VK_ERROR_MEMORY_MAP_FAILED => error.MemoryMapFailed,
        c.VK_ERROR_LAYER_NOT_PRESENT => error.LayerNotPresent,
        c.VK_ERROR_EXTENSION_NOT_PRESENT => error.ExtensionNotPresent,
        c.VK_ERROR_FEATURE_NOT_PRESENT => error.FeatureNotPresent,
        c.VK_ERROR_INCOMPATIBLE_DRIVER => error.IncompatibleDriver,
        c.VK_ERROR_TOO_MANY_OBJECTS => error.TooManyObjects,
        c.VK_ERROR_FORMAT_NOT_SUPPORTED => error.FormatNotSupported,
        c.VK_ERROR_FRAGMENTED_POOL => error.FragmentedPool,
        c.VK_ERROR_OUT_OF_POOL_MEMORY => error.OutOfPoolMemory,
        c.VK_ERROR_INVALID_EXTERNAL_HANDLE => error.InvalidExternalHandle,
        c.VK_ERROR_FRAGMENTATION => error.Fragmentation,
        c.VK_ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.InvalidOpaqueCaptureAddress,
        c.VK_PIPELINE_COMPILE_REQUIRED => error.PipelineCompileRequired,
        c.VK_ERROR_SURFACE_LOST_KHR => error.SurfaceLostKhr,
        c.VK_ERROR_NATIVE_WINDOW_IN_USE_KHR => error.NativeWindowInUseKhr,
        c.VK_SUBOPTIMAL_KHR => error.SuboptimalKhr,
        c.VK_ERROR_OUT_OF_DATE_KHR => error.OutOfDateKhr,
        c.VK_ERROR_INCOMPATIBLE_DISPLAY_KHR => error.IncompatibleDisplayKhr,
        c.VK_ERROR_VALIDATION_FAILED_EXT => error.ValidationFailedExt,
        c.VK_ERROR_INVALID_SHADER_NV => error.InvalidShaderNv,
        c.VK_ERROR_IMAGE_USAGE_NOT_SUPPORTED_KHR => error.ImageUsageNotSupportedKhr,
        c.VK_ERROR_VIDEO_PICTURE_LAYOUT_NOT_SUPPORTED_KHR => error.VideoPictureLayoutNotSupportedKhr,
        c.VK_ERROR_VIDEO_PROFILE_OPERATION_NOT_SUPPORTED_KHR => error.VideoProfileOperationNotSupportedKhr,
        c.VK_ERROR_VIDEO_PROFILE_FORMAT_NOT_SUPPORTED_KHR => error.VideoProfileFormatNotSupportedKhr,
        c.VK_ERROR_VIDEO_PROFILE_CODEC_NOT_SUPPORTED_KHR => error.VideoProfileCodecNotSupportedKhr,
        c.VK_ERROR_VIDEO_STD_VERSION_NOT_SUPPORTED_KHR => error.VideoStdVersionNotSupportedKhr,
        c.VK_ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT => error.InvalidDrmFormatModifierPlaneLayoutExt,
        c.VK_ERROR_NOT_PERMITTED_KHR => error.NotPermittedKhr,
        c.VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT => error.FullScreenExclusiveModeLostExt,
        c.VK_THREAD_IDLE_KHR => error.ThreadIdleKhr,
        c.VK_THREAD_DONE_KHR => error.ThreadDoneKhr,
        c.VK_OPERATION_DEFERRED_KHR => error.OperationDeferredKhr,
        c.VK_OPERATION_NOT_DEFERRED_KHR => error.OperationNotDeferredKhr,
        c.VK_ERROR_INVALID_VIDEO_STD_PARAMETERS_KHR => error.InvalidVideoStdParametersKhr,
        c.VK_ERROR_COMPRESSION_EXHAUSTED_EXT => error.CompressionExhaustedExt,
        c.VK_INCOMPATIBLE_SHADER_BINARY_EXT => error.IncompatibleShaderBinaryExt,
        c.VK_ERROR_UNKNOWN => error.Unknown,
        else => error.Unknown,
    };
}

pub fn VkFunc(
    func: enum { create_debug_utils_messenger_ext, destroy_debug_utils_messenger },
) type {
    const f: struct { [*:0]const u8, type } = switch (func) {
        .create_debug_utils_messenger_ext => .{ "vkCreateDebugUtilsMessengerEXT", c.PFN_vkCreateDebugUtilsMessengerEXT },
        .destroy_debug_utils_messenger => .{ "vkDestroyDebugUtilsMessengerEXT", c.PFN_vkDestroyDebugUtilsMessengerEXT },
    };

    return struct {
        pub fn load(instance: *Instance) !@typeInfo(f.@"1").optional.child {
            const ptr = c.vkGetInstanceProcAddr(instance.toC(), f.@"0") orelse return error.VkGetInstanceProcAddr;
            return @ptrCast(ptr);
        }
    };
}

pub const DebugMessenger = opaque {
    pub const CType = c.VkDebugUtilsMessengerEXT;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub const Config = struct {
        severities: struct {
            verbose: bool = false,
            warning: bool = true,
            @"error": bool = true,
        } = .{},
    };

    pub fn init(instance: *Instance, config: Config) !*@This() {
        // zig fmt: off
        const message_severity: u32 = @intCast(
            if (config.severities.verbose) c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT else 0 |
            if (config.severities.warning) c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT else 0 |
            if (config.severities.@"error") c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT else 0);
        // zig fmt: on

        const message_type: u32 = c.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
            c.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
            c.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;

        var create_info: c.VkDebugUtilsMessengerCreateInfoEXT = .{
            .sType = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
            .pNext = null,
            .flags = 0,
            .messageSeverity = message_severity,
            .messageType = message_type,
            .pfnUserCallback = callback,
            .pUserData = null,
        };

        var messenger: c.VkDebugUtilsMessengerEXT = undefined;
        const createDebugUtilsMessengerExt = try VkFunc(.create_debug_utils_messenger_ext).load(instance);
        try vkCheck(createDebugUtilsMessengerExt(instance.toC(), &create_info, null, &messenger));

        return @ptrCast(messenger);
    }

    pub fn deinit(self: *@This(), instance: *Instance) void {
        const destroyDebugUtilsMessenger = VkFunc(.destroy_debug_utils_messenger).load(instance) catch unreachable;
        destroyDebugUtilsMessenger(instance.toC(), self.toC(), null);
    }

    fn callback(severity: c.VkDebugUtilsMessageSeverityFlagBitsEXT, _: c.VkDebugUtilsMessageTypeFlagsEXT, callback_data: [*c]const c.VkDebugUtilsMessengerCallbackDataEXT, _: ?*anyopaque) callconv(.c) c.VkBool32 {
        switch (severity) {
            c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT => std.log.info("VK {s}", .{callback_data.*.pMessage}),
            c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT => std.log.info("VK {s}", .{callback_data.*.pMessage}),
            c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT => std.log.warn("VK {s}", .{callback_data.*.pMessage}),
            c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT => std.log.err("VK {s}", .{callback_data.*.pMessage}),
            else => unreachable,
        }

        return c.VK_FALSE;
    }
};

pub const Instance = opaque {
    pub const CType = c.VkInstance;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub fn init(extensions: ?[]const [*:0]const u8, layers: ?[]const [*:0]const u8) !*@This() {
        // TODO: Add checks so no invalid extensions or layers get past

        var create_info: c.VkInstanceCreateInfo = .{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .ppEnabledExtensionNames = if (extensions != null) extensions.?.ptr else null,
            .enabledExtensionCount = if (extensions != null) @intCast(extensions.?.len) else 0,
            .ppEnabledLayerNames = if (layers != null) layers.?.ptr else null,
            .enabledLayerCount = if (layers != null) @intCast(layers.?.len) else 0,

            .pApplicationInfo = &.{
                .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
                .pApplicationName = "App",
                .applicationVersion = c.VK_MAKE_VERSION(1, 0, 0),
                .pEngineName = "Engine",
                .engineVersion = c.VK_MAKE_VERSION(1, 0, 0),
                .apiVersion = c.VK_API_VERSION_1_3,
            },
        };

        var instance: c.VkInstance = undefined;
        try vkCheck(c.vkCreateInstance(&create_info, null, &instance));
        return @ptrCast(instance);
    }

    pub fn deinit(self: *@This()) void {
        c.vkDestroyInstance(self.toC(), null);
    }
};

pub const Surface = opaque {
    pub const CType = c.VkSurfaceKHR;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub fn init(_: *Instance) !*@This() {
        // TODO: Make not hard coded and allow for other windowing libraries

        @panic("Not implemented use the surface sub config instead");
        // return @ptrCast(null);
    }

    pub fn deinit(self: *@This(), instance: *Instance) void {
        c.vkDestroySurfaceKHR(instance.toC(), self.toC(), null);
    }
};

pub const PhysicalDevice = opaque {
    pub const CType = c.VkPhysicalDevice;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub fn init(instance: *Instance, surface: *Surface) !struct { *@This(), u32 } {
        var device_count: u32 = 0;
        try vkCheck(c.vkEnumeratePhysicalDevices(instance.toC(), &device_count, null));
        if (device_count == 0) return error.NoPhysicalDevices;

        var devices: [8]c.VkPhysicalDevice = undefined;
        try vkCheck(c.vkEnumeratePhysicalDevices(instance.toC(), &device_count, &devices));

        for (devices[0..device_count]) |device| {
            var properties: c.VkPhysicalDeviceProperties = undefined;
            c.vkGetPhysicalDeviceProperties(device, &properties);

            var queue_family_count: u32 = 0;
            c.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, null);

            var queue_families: [16]c.VkQueueFamilyProperties = undefined;
            c.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, &queue_families);

            for (queue_families[0..queue_family_count], 0..) |queue_family, queue_family_index| {
                const supports_graphics = (queue_family.queueFlags & c.VK_QUEUE_GRAPHICS_BIT) != 0;

                var present_supported: c.VkBool32 = 0;
                try vkCheck(c.vkGetPhysicalDeviceSurfaceSupportKHR(device, @intCast(queue_family_index), surface.toC(), &present_supported));

                if (supports_graphics and present_supported != 0) {
                    std.log.info("Picked device: {s}, queue family: {d}\n", .{ properties.deviceName, queue_family_index });

                    return .{ @ptrCast(device), @intCast(queue_family_index) };
                }
            }
        }

        return error.NoSuitablePhysicalDevice;
    }

    pub fn deinit(_: @This()) void {}
};

pub const Device = opaque {
    pub const CType = c.VkDevice;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub const Queue = opaque {
        pub inline fn toC(self: *Queue) c.VkQueue {
            return @ptrCast(self);
        }
    };

    pub fn init(physical_device: *PhysicalDevice, queue_family_index: u32, extensions: ?[]const [*:0]const u8) !*@This() {
        var dynamic_rendering_features: c.VkPhysicalDeviceDynamicRenderingFeatures = .{
            .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
            .dynamicRendering = c.VK_TRUE,
        };

        var queue_priority: f32 = 1.0;
        const queue_info: c.VkDeviceQueueCreateInfo = .{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = &dynamic_rendering_features,
            .queueFamilyIndex = queue_family_index,
            .queueCount = 1,
            .pQueuePriorities = &queue_priority,
            .flags = 0,
        };

        var features: c.VkPhysicalDeviceFeatures = undefined;
        c.vkGetPhysicalDeviceFeatures(physical_device.toC(), &features);

        const device_info = c.VkDeviceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .queueCreateInfoCount = 1,
            .pQueueCreateInfos = &queue_info,
            .pEnabledFeatures = &features,
            .enabledExtensionCount = if (extensions != null) @intCast(extensions.?.len) else 0,
            .ppEnabledExtensionNames = if (extensions != null) extensions.?.ptr else null,
        };

        var device: c.VkDevice = undefined;
        try vkCheck(c.vkCreateDevice(physical_device.toC(), &device_info, null, &device));
        var queue: c.VkQueue = undefined;
        c.vkGetDeviceQueue(device, queue_family_index, 0, &queue);

        return @ptrCast(device);
    }

    pub fn deinit(self: *@This()) void {
        c.vkDestroyDevice(self.toC(), null);
    }

    pub inline fn getQueue(self: *@This(), index: u32) Queue {
        var queue: c.VkQueue = undefined;
        c.vkGetDeviceQueue(self.toC(), index, 0, &queue);
        return @ptrCast(queue);
    }
};

pub const GraphicsPipeline = opaque {
    pub const CType = c.VkPipeline;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub fn init(device: Device) !*@This() {
        const create_infos: []c.VkGraphicsPipelineCreateInfo = &.{
            c.VkGraphicsPipelineCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            },
        };

        var pipeline: c.VkPipeline = undefined;
        try vkCheck(c.vkCreateGraphicsPipelines(device.toC(), null, @intCast(create_infos.len), create_infos.ptr, null, &pipeline));

        return @ptrCast(pipeline);
    }

    pub fn deinit(self: *@This()) void {
        c.vkDestroyDevice(self.toC(), null);
    }
};
