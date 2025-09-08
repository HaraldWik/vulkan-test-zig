const std = @import("std");
pub const vk = @import("vulkan");

pub fn vkCheck(result: vk.VkResult) !void {
    if (result != vk.VK_SUCCESS) return switch (result) {
        vk.VK_ERROR_OUT_OF_HOST_MEMORY => error.OutOfHostMemory,
        vk.VK_ERROR_OUT_OF_DEVICE_MEMORY => error.OutOfDeviceMemory,
        vk.VK_ERROR_INITIALIZATION_FAILED => error.InitializationFailed,
        vk.VK_ERROR_DEVICE_LOST => error.DeviceLost,
        vk.VK_ERROR_MEMORY_MAP_FAILED => error.MemoryMapFailed,
        vk.VK_ERROR_LAYER_NOT_PRESENT => error.LayerNotPresent,
        vk.VK_ERROR_EXTENSION_NOT_PRESENT => error.ExtensionNotPresent,
        vk.VK_ERROR_FEATURE_NOT_PRESENT => error.FeatureNotPresent,
        vk.VK_ERROR_INCOMPATIBLE_DRIVER => error.IncompatibleDriver,
        vk.VK_ERROR_TOO_MANY_OBJECTS => error.TooManyObjects,
        vk.VK_ERROR_FORMAT_NOT_SUPPORTED => error.FormatNotSupported,
        vk.VK_ERROR_FRAGMENTED_POOL => error.FragmentedPool,
        vk.VK_ERROR_OUT_OF_POOL_MEMORY => error.OutOfPoolMemory,
        vk.VK_ERROR_INVALID_EXTERNAL_HANDLE => error.InvalidExternalHandle,
        vk.VK_ERROR_FRAGMENTATION => error.Fragmentation,
        vk.VK_ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.InvalidOpaqueCaptureAddress,
        vk.VK_PIPELINE_COMPILE_REQUIRED => error.PipelineCompileRequired,
        vk.VK_ERROR_SURFACE_LOST_KHR => error.SurfaceLostKhr,
        vk.VK_ERROR_NATIVE_WINDOW_IN_USE_KHR => error.NativeWindowInUseKhr,
        vk.VK_SUBOPTIMAL_KHR => error.SuboptimalKhr,
        vk.VK_ERROR_OUT_OF_DATE_KHR => error.OutOfDateKhr,
        vk.VK_ERROR_INCOMPATIBLE_DISPLAY_KHR => error.IncompatibleDisplayKhr,
        vk.VK_ERROR_VALIDATION_FAILED_EXT => error.ValidationFailedExt,
        vk.VK_ERROR_INVALID_SHADER_NV => error.InvalidShaderNv,
        vk.VK_ERROR_IMAGE_USAGE_NOT_SUPPORTED_KHR => error.ImageUsageNotSupportedKhr,
        vk.VK_ERROR_VIDEO_PICTURE_LAYOUT_NOT_SUPPORTED_KHR => error.VideoPictureLayoutNotSupportedKhr,
        vk.VK_ERROR_VIDEO_PROFILE_OPERATION_NOT_SUPPORTED_KHR => error.VideoProfileOperationNotSupportedKhr,
        vk.VK_ERROR_VIDEO_PROFILE_FORMAT_NOT_SUPPORTED_KHR => error.VideoProfileFormatNotSupportedKhr,
        vk.VK_ERROR_VIDEO_PROFILE_CODEC_NOT_SUPPORTED_KHR => error.VideoProfileCodecNotSupportedKhr,
        vk.VK_ERROR_VIDEO_STD_VERSION_NOT_SUPPORTED_KHR => error.VideoStdVersionNotSupportedKhr,
        vk.VK_ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT => error.InvalidDrmFormatModifierPlaneLayoutExt,
        vk.VK_ERROR_NOT_PERMITTED_KHR => error.NotPermittedKhr,
        vk.VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT => error.FullScreenExclusiveModeLostExt,
        vk.VK_THREAD_IDLE_KHR => error.ThreadIdleKhr,
        vk.VK_THREAD_DONE_KHR => error.ThreadDoneKhr,
        vk.VK_OPERATION_DEFERRED_KHR => error.OperationDeferredKhr,
        vk.VK_OPERATION_NOT_DEFERRED_KHR => error.OperationNotDeferredKhr,
        vk.VK_ERROR_INVALID_VIDEO_STD_PARAMETERS_KHR => error.InvalidVideoStdParametersKhr,
        vk.VK_ERROR_COMPRESSION_EXHAUSTED_EXT => error.CompressionExhaustedExt,
        vk.VK_INCOMPATIBLE_SHADER_BINARY_EXT => error.IncompatibleShaderBinaryExt,
        vk.VK_ERROR_UNKNOWN => error.Unknown,
        else => error.Unknown,
    };
}

pub fn VkFunc(
    func: enum { create_debug_utils_messenger_ext, destroy_debug_utils_messenger },
) type {
    const f: struct { [*:0]const u8, type } = switch (func) {
        .create_debug_utils_messenger_ext => .{ "vkCreateDebugUtilsMessengerEXT", vk.PFN_vkCreateDebugUtilsMessengerEXT },
        .destroy_debug_utils_messenger => .{ "vkDestroyDebugUtilsMessengerEXT", vk.PFN_vkDestroyDebugUtilsMessengerEXT },
    };

    return struct {
        pub fn load(instance: *Instance) !@typeInfo(f.@"1").optional.child {
            const ptr = vk.vkGetInstanceProcAddr(instance.toC(), f.@"0") orelse return error.VkGetInstanceProcAddr;
            return @ptrCast(ptr);
        }
    };
}

pub const DebugMessenger = opaque {
    pub const CType = vk.VkDebugUtilsMessengerEXT;

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
            if (config.severities.verbose) vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT else 0 |
            if (config.severities.warning) vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT else 0 |
            if (config.severities.@"error") vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT else 0);
        // zig fmt: on

        const message_type: u32 = vk.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
            vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
            vk.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;

        var create_info: vk.VkDebugUtilsMessengerCreateInfoEXT = .{
            .sType = vk.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
            .pNext = null,
            .flags = 0,
            .messageSeverity = message_severity,
            .messageType = message_type,
            .pfnUserCallback = callback,
            .pUserData = null,
        };

        var messenger: vk.VkDebugUtilsMessengerEXT = undefined;
        const createDebugUtilsMessengerExt = try VkFunc(.create_debug_utils_messenger_ext).load(instance);
        try vkCheck(createDebugUtilsMessengerExt(instance.toC(), &create_info, null, &messenger));

        return @ptrCast(messenger);
    }

    pub fn deinit(self: *@This(), instance: *Instance) void {
        const destroyDebugUtilsMessenger = VkFunc(.destroy_debug_utils_messenger).load(instance) catch unreachable;
        destroyDebugUtilsMessenger(instance.toC(), self.toC(), null);
    }

    fn callback(severity: vk.VkDebugUtilsMessageSeverityFlagBitsEXT, _: vk.VkDebugUtilsMessageTypeFlagsEXT, callback_data: [*c]const vk.VkDebugUtilsMessengerCallbackDataEXT, _: ?*anyopaque) callconv(.c) vk.VkBool32 {
        switch (severity) {
            vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT => std.log.info("VK {s}", .{callback_data.*.pMessage}),
            vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT => std.log.info("VK {s}", .{callback_data.*.pMessage}),
            vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT => std.log.warn("VK {s}", .{callback_data.*.pMessage}),
            vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT => std.log.err("VK {s}", .{callback_data.*.pMessage}),
            else => unreachable,
        }

        return vk.VK_FALSE;
    }
};

pub const Instance = opaque {
    pub const CType = vk.VkInstance;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub fn init(extensions: ?[]const [*:0]const u8, layers: ?[]const [*:0]const u8) !*@This() {
        // TODO: Add checks so no invalid extensions or layers get past

        var create_info: vk.VkInstanceCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .ppEnabledExtensionNames = if (extensions != null) extensions.?.ptr else null,
            .enabledExtensionCount = if (extensions != null) @intCast(extensions.?.len) else 0,
            .ppEnabledLayerNames = if (layers != null) layers.?.ptr else null,
            .enabledLayerCount = if (layers != null) @intCast(layers.?.len) else 0,

            .pApplicationInfo = &.{
                .sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO,
                .pApplicationName = "App",
                .applicationVersion = vk.VK_MAKE_VERSION(1, 0, 0),
                .pEngineName = "Engine",
                .engineVersion = vk.VK_MAKE_VERSION(1, 0, 0),
                .apiVersion = vk.VK_API_VERSION_1_3,
            },
        };

        var instance: vk.VkInstance = undefined;
        try vkCheck(vk.vkCreateInstance(&create_info, null, &instance));
        return @ptrCast(instance);
    }

    pub fn deinit(self: *@This()) void {
        vk.vkDestroyInstance(self.toC(), null);
    }
};

pub const Surface = opaque {
    pub const CType = vk.VkSurfaceKHR;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub fn init(_: *Instance) !*@This() {
        // TODO: Make not hard coded and allow for other windowing libraries

        @panic("Not implemented use the surface sub config instead");
        // return @ptrCast(null);
    }

    pub fn deinit(self: *@This(), instance: *Instance) void {
        vk.vkDestroySurfaceKHR(instance.toC(), self.toC(), null);
    }
};

pub const PhysicalDevice = opaque {
    pub const CType = vk.VkPhysicalDevice;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub fn init(instance: *Instance, surface: *Surface) !struct { *@This(), u32 } {
        var device_count: u32 = 0;
        try vkCheck(vk.vkEnumeratePhysicalDevices(instance.toC(), &device_count, null));
        if (device_count == 0) return error.NoPhysicalDevices;

        var devices: [8]vk.VkPhysicalDevice = undefined;
        try vkCheck(vk.vkEnumeratePhysicalDevices(instance.toC(), &device_count, &devices));

        for (devices[0..device_count]) |device| {
            var properties: vk.VkPhysicalDeviceProperties = undefined;
            vk.vkGetPhysicalDeviceProperties(device, &properties);

            var queue_family_count: u32 = 0;
            vk.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, null);

            var queue_families: [16]vk.VkQueueFamilyProperties = undefined;
            vk.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, &queue_families);

            for (queue_families[0..queue_family_count], 0..) |queue_family, queue_family_index| {
                const supports_graphics = (queue_family.queueFlags & vk.VK_QUEUE_GRAPHICS_BIT) != 0;

                var present_supported: vk.VkBool32 = 0;
                try vkCheck(vk.vkGetPhysicalDeviceSurfaceSupportKHR(device, @intCast(queue_family_index), surface.toC(), &present_supported));

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
    pub const CType = vk.VkDevice;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub const Queue = opaque {
        pub inline fn toC(self: *Queue) vk.VkQueue {
            return @ptrCast(self);
        }
    };

    pub fn init(physical_device: *PhysicalDevice, queue_family_index: u32, extensions: ?[]const [*:0]const u8) !*@This() {
        var dynamic_rendering_features: vk.VkPhysicalDeviceDynamicRenderingFeatures = .{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
            .dynamicRendering = vk.VK_TRUE,
        };

        var queue_priority: f32 = 1.0;
        const queue_info: vk.VkDeviceQueueCreateInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = &dynamic_rendering_features,
            .queueFamilyIndex = queue_family_index,
            .queueCount = 1,
            .pQueuePriorities = &queue_priority,
            .flags = 0,
        };

        var features: vk.VkPhysicalDeviceFeatures = undefined;
        vk.vkGetPhysicalDeviceFeatures(physical_device.toC(), &features);

        const device_info = vk.VkDeviceCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .queueCreateInfoCount = 1,
            .pQueueCreateInfos = &queue_info,
            .pEnabledFeatures = &features,
            .enabledExtensionCount = if (extensions != null) @intCast(extensions.?.len) else 0,
            .ppEnabledExtensionNames = if (extensions != null) extensions.?.ptr else null,
        };

        var device: vk.VkDevice = undefined;
        try vkCheck(vk.vkCreateDevice(physical_device.toC(), &device_info, null, &device));
        var queue: vk.VkQueue = undefined;
        vk.vkGetDeviceQueue(device, queue_family_index, 0, &queue);

        return @ptrCast(device);
    }

    pub fn deinit(self: *@This()) void {
        vk.vkDestroyDevice(self.toC(), null);
    }

    pub inline fn getQueue(self: *@This(), index: u32) Queue {
        var queue: vk.VkQueue = undefined;
        vk.vkGetDeviceQueue(self.toC(), index, 0, &queue);
        return @ptrCast(queue);
    }
};

pub const GraphicsPipeline = opaque {
    pub const CType = vk.VkPipeline;

    pub inline fn toC(self: *@This()) CType {
        return @ptrCast(self);
    }

    pub fn init(device: Device) !*@This() {
        const create_infos: []vk.VkGraphicsPipelineCreateInfo = &.{
            vk.VkGraphicsPipelineCreateInfo{
                .sType = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            },
        };

        var pipeline: vk.VkPipeline = undefined;
        try vkCheck(vk.vkCreateGraphicsPipelines(device.toC(), null, @intCast(create_infos.len), create_infos.ptr, null, &pipeline));

        return @ptrCast(pipeline);
    }

    pub fn deinit(self: *@This()) void {
        vk.vkDestroyDevice(self.toC(), null);
    }
};

// pub const Swapchain = opaque {
//     pub const CType = vk.VkSwapchainKHR;

//     pub inline fn toC(self: *@This()) CType {
//         return @ptrCast(self);
//     }

//     pub fn init(device: Device, surface: Surface) !*@This() {
//         const images: []vk.VkImage = .{undefined};

//         const create_info: vk.VkSwapchainCreateInfoKHR = .{
//             .sType = vk.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
//             .surface = surface.toC(),
//             .minImageCount = @intCast(images.len),
//             .imageFormat = vk.VK_IMAGE_
//         };

//         var pipeline: vk.VkPipeline = undefined;
//         try vkCheck(vk.vkCreateGraphicsPipelines(device.toC(), null, @intCast(create_infos.len), create_infos.ptr, null, &pipeline));

//         return @ptrCast(pipeline);
//     }

//     pub fn deinit(self: *@This()) void {
//         vk.vkDestroyDevice(self.toC(), null);
//     }
// };
