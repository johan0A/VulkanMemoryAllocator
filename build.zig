const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options = .{
        .{ "VMA_STATIC_VULKAN_FUNCTIONS", bool, "Use statically linked Vulkan functions" },
        .{ "VMA_DYNAMIC_VULKAN_FUNCTIONS", bool, "Dynamically load Vulkan functions" },
        .{ "VMA_VULKAN_VERSION", i64, "Target specific Vulkan API version" },
        .{ "VMA_STATS_STRING_ENABLED", bool, "Enable vmaBuildStatsString / vmaFreeStatsString" },
        .{ "VMA_DEDICATED_ALLOCATION", bool, "Enable KHR dedicated allocation support" },
        .{ "VMA_BIND_MEMORY2", bool, "Enable KHR bind memory 2 support" },
        .{ "VMA_MEMORY_BUDGET", bool, "Enable memory budget tracking" },
        .{ "VMA_BUFFER_DEVICE_ADDRESS", bool, "Enable buffer device address support" },
        .{ "VMA_MEMORY_PRIORITY", bool, "Enable memory priority support" },
        .{ "VMA_KHR_MAINTENANCE4", bool, "Enable KHR maintenance4 support" },
        .{ "VMA_KHR_MAINTENANCE5", bool, "Enable KHR maintenance5 support" },
        .{ "VMA_EXTERNAL_MEMORY", bool, "Enable external memory support" },
        .{ "VMA_EXTERNAL_MEMORY_WIN32", bool, "Enable Win32 external memory handle support" },

        .{ "VMA_DEBUG_ALWAYS_DEDICATED_MEMORY", bool, "Force every allocation into its own VkDeviceMemory" },
        .{ "VMA_DEBUG_INITIALIZE_ALLOCATIONS", bool, "Fill new/destroyed allocations with a bit pattern" },
        .{ "VMA_DEBUG_DETECT_CORRUPTION", bool, "Enable corruption detection (requires VMA_DEBUG_MARGIN > 0)" },
        .{ "VMA_DEBUG_GLOBAL_MUTEX", bool, "Single global mutex protecting all entry points" },
        .{ "VMA_DEBUG_DONT_EXCEED_MAX_MEMORY_ALLOCATION_COUNT", bool, "Respect maxMemoryAllocationCount" },
        .{ "VMA_DEBUG_DONT_EXCEED_HEAP_SIZE_WITH_ALLOCATION_SIZE", bool, "Refuse allocations exceeding heap size" },
        .{ "VMA_MAPPING_HYSTERESIS_ENABLED", bool, "Enable mapping hysteresis to avoid frequent map/unmap" },
        .{ "VMA_MIN_ALIGNMENT", i64, "Minimum alignment of all allocations in bytes (power of two)" },
        .{ "VMA_DEBUG_MARGIN", i64, "Margin in bytes after every allocation for corruption detection" },
        .{ "VMA_DEBUG_MIN_BUFFER_IMAGE_GRANULARITY", i64, "Override minimum bufferImageGranularity" },
        .{ "VMA_SMALL_HEAP_MAX_SIZE", i64, "Max heap size in bytes to consider 'small'" },
        .{ "VMA_DEFAULT_LARGE_HEAP_BLOCK_SIZE", i64, "Default block size in bytes for large heap allocations" },
    };

    const config_h = b.addConfigHeader(.{ .include_path = "vk_mem_alloc_config.h" }, .{});

    inline for (options) |entry| {
        const name, const T, const desc = entry;
        if (b.option(T, name, desc)) |value| {
            config_h.addValue(name, T, value);
        }
    }

    const root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });

    root_module.addCSourceFile(.{
        .file = b.addWriteFiles().add("stub.cpp",
            \\#include "vk_mem_alloc_config.h"
            \\#define VMA_IMPLEMENTATION
            \\#include "vk_mem_alloc.h"
        ),
        .flags = &.{"-std=c++17"},
    });

    root_module.addIncludePath(config_h.getOutputDir());

    const upstream = b.dependency("VulkanMemoryAllocator", .{});
    root_module.addIncludePath(upstream.path("include/"));

    if (b.option(std.Build.LazyPath, "vulkan-include-path", "Path to Vulkan headers")) |vulkan_include_path| {
        root_module.addIncludePath(vulkan_include_path);

        const lib = b.addLibrary(.{
            .name = "VulkanMemoryAllocator",
            .linkage = b.option(std.builtin.LinkMode, "linkage", "defaults to static") orelse .static,
            .root_module = root_module,
        });
        b.installArtifact(lib);
        lib.installHeader(upstream.path("include/vk_mem_alloc.h"), "vk_mem_alloc.h");
        lib.installHeader(config_h.getOutputFile(), "vk_mem_alloc_config.h");
    } else {
        const fail = b.addFail("missing vulkan headers, specify a path to vulkan headers using the vulkan-include-path option");
        b.getInstallStep().dependOn(&fail.step);
    }
}
