const std = @import("std");

pub fn build(b: *std.Build) !void {
    const lib = b.addLibrary(.{
        .name = "VulkanMemoryAllocator",
        .linkage = b.option(std.builtin.LinkMode, "linkage", "defaults to static") orelse .static,
        .root_module = b.createModule(.{
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
        }),
    });
    lib.linkLibCpp();

    const install_vulkan_headers = b.option(bool, "install-vulkan-headers", "(defaults to false)") orelse false;

    if (b.option(std.Build.LazyPath, "vulkan-headers-path", "Path to Vulkan headers (defaults to bundled headers)")) |vulkan_headers_path| {
        lib.addIncludePath(vulkan_headers_path);
        if (install_vulkan_headers) lib.installHeadersDirectory(vulkan_headers_path, "", .{});
    } else {
        if (b.lazyDependency("vulkan_headers", .{})) |vulkan_headers| {
            lib.linkLibrary(vulkan_headers.artifact("vulkan-headers"));
            if (install_vulkan_headers) lib.installLibraryHeaders(vulkan_headers.artifact("vulkan-headers"));
        }
    }

    const upstream = b.dependency("VulkanMemoryAllocator", .{});
    lib.installHeader(upstream.path("include/vk_mem_alloc.h"), "vk_mem_alloc.h");
    lib.addIncludePath(upstream.path("include/"));

    lib.addCSourceFile(.{
        .file = b.addWriteFiles().add("vk_mem_alloc.cpp", "#include \"vk_mem_alloc.h\""),
        .flags = &.{ "-DVMA_IMPLEMENTATION", "-std=c++17" },
    });

    {
        const allocPrint = std.fmt.allocPrint;
        const bool_options = [_][2][]const u8{
            .{ "macro_static_vulkan_functions", "VMA_STATIC_VULKAN_FUNCTIONS" },
            .{ "macro_dynamic_vulkan_functions", "VMA_DYNAMIC_VULKAN_FUNCTIONS" },
            .{ "macro_stats_string_enabled", "VMA_STATS_STRING_ENABLED" },
            .{ "macro_debug_initialize_allocations", "VMA_DEBUG_INITIALIZE_ALLOCATIONS" },
            .{ "macro_debug_detect_corruption", "VMA_DEBUG_DETECT_CORRUPTION" },
            .{ "macro_debug_global_mutex", "VMA_DEBUG_GLOBAL_MUTEX" },
            .{ "macro_use_stl_shared_mutex", "VMA_USE_STL_SHARED_MUTEX" },
            .{ "macro_debug_always_dedicated_memory", "VMA_DEBUG_ALWAYS_DEDICATED_MEMORY" },
            .{ "macro_debug_dont_exceed_max_memory_allocation_count", "VMA_DEBUG_DONT_EXCEED_MAX_MEMORY_ALLOCATION_COUNT" },
            .{ "macro_mapping_hysteresis_enabled", "VMA_MAPPING_HYSTERESIS_ENABLED" },
        };
        for (bool_options) |bool_option| {
            if (b.option(bool, bool_option[0], "")) |opt|
                lib.root_module.addCMacro(bool_option[1], try allocPrint(b.allocator, "{}", .{@intFromBool(opt)}));
        }

        if (b.option(i64, "macro_debug_min_buffer_image_granularity", "")) |opt|
            lib.root_module.addCMacro("VMA_DEBUG_MIN_BUFFER_IMAGE_GRANULARITY", try allocPrint(b.allocator, "{}", .{opt}));
        if (b.option(i64, "macro_debug_margin", "")) |opt|
            lib.root_module.addCMacro("VMA_DEBUG_MARGIN", try allocPrint(b.allocator, "{}", .{opt}));
        if (b.option(i64, "macro_min_alignment", "")) |opt|
            lib.root_module.addCMacro("VMA_MIN_ALIGNMENT", try allocPrint(b.allocator, "{}", .{opt}));

        if (b.option(u64, "macro_small_heap_max_size", "")) |opt|
            lib.root_module.addCMacro("VMA_SMALL_HEAP_MAX_SIZE", try allocPrint(b.allocator, "{}ull", .{opt}));
        if (b.option(u64, "macro_default_large_heap_block_size", "")) |opt|
            lib.root_module.addCMacro("VMA_DEFAULT_LARGE_HEAP_BLOCK_SIZE", try allocPrint(b.allocator, "{}ull", .{opt}));

        if (b.option([]const u8, "macro_null", "")) |opt|
            lib.root_module.addCMacro("VMA_NULL", opt);
        if (b.option([]const u8, "macro_configuration_user_includes_h", "")) |opt|
            lib.root_module.addCMacro("VMA_CONFIGURATION_USER_INCLUDES_H", try allocPrint(b.allocator, "\"{s}\"", .{opt}));
    }

    b.installArtifact(lib);
}
