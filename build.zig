const std = @import("std");

pub fn build(b: *std.Build) !void {
    const version = std.SemanticVersion{
        .major = 3,
        .minor = 2,
        .patch = 1,
    };

    const lib = b.addLibrary(.{
        .name = "vma",
        .linkage = b.option(std.builtin.LinkMode, "linkage", "") orelse .static,
        .root_module = b.createModule(.{
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
        }),
        .version = version,
    });
    lib.linkLibCpp();

    const vulkan_headers = b.dependency("vulkan_headers", .{});
    lib.linkLibrary(vulkan_headers.artifact("vulkan-headers"));

    const upstream = b.dependency("VulkanMemoryAllocator", .{});
    lib.installHeader(upstream.path("include/vk_mem_alloc.h"), "");
    lib.addIncludePath(upstream.path("include"));
    lib.addCSourceFile(.{
        .file = b.addWriteFiles().add("vk_mem_alloc.cpp", "#include \"vk_mem_alloc.h\""),
        .flags = &.{ "-DVMA_IMPLEMENTATION", "-std=c++14" },
    });

    {
        const allocPrint = std.fmt.allocPrint;
        const bool_options = [_][2][]const u8{
            .{ "static_vulkan_functions", "VMA_STATIC_VULKAN_FUNCTIONS" },
            .{ "dynamic_vulkan_functions", "VMA_DYNAMIC_VULKAN_FUNCTIONS" },
            .{ "stats_string_enabled", "VMA_STATS_STRING_ENABLED" },
            .{ "debug_initialize_allocations", "VMA_DEBUG_INITIALIZE_ALLOCATIONS" },
            .{ "debug_detect_corruption", "VMA_DEBUG_DETECT_CORRUPTION" },
            .{ "debug_global_mutex", "VMA_DEBUG_GLOBAL_MUTEX" },
            .{ "use_stl_shared_mutex", "VMA_USE_STL_SHARED_MUTEX" },
            .{ "debug_always_dedicated_memory", "VMA_DEBUG_ALWAYS_DEDICATED_MEMORY" },
            .{ "debug_dont_exceed_max_memory_allocation_count", "VMA_DEBUG_DONT_EXCEED_MAX_MEMORY_ALLOCATION_COUNT" },
            .{ "mapping_hysteresis_enabled", "VMA_MAPPING_HYSTERESIS_ENABLED" },
        };
        for (bool_options) |bool_option| {
            if (b.option(bool, bool_option[0], "")) |opt|
                lib.root_module.addCMacro(bool_option[1], try allocPrint(b.allocator, "{}", .{@intFromBool(opt)}));
        }

        if (b.option(i64, "debug_min_buffer_image_granularity", "")) |opt|
            lib.root_module.addCMacro("VMA_DEBUG_MIN_BUFFER_IMAGE_GRANULARITY", try allocPrint(b.allocator, "{}", .{opt}));
        if (b.option(i64, "debug_margin", "")) |opt|
            lib.root_module.addCMacro("VMA_DEBUG_MARGIN", try allocPrint(b.allocator, "{}", .{opt}));
        if (b.option(i64, "min_alignment", "")) |opt|
            lib.root_module.addCMacro("VMA_MIN_ALIGNMENT", try allocPrint(b.allocator, "{}", .{opt}));

        if (b.option(u64, "small_heap_max_size", "")) |opt|
            lib.root_module.addCMacro("VMA_SMALL_HEAP_MAX_SIZE", try allocPrint(b.allocator, "{}ull", .{opt}));
        if (b.option(u64, "default_large_heap_block_size", "")) |opt|
            lib.root_module.addCMacro("VMA_DEFAULT_LARGE_HEAP_BLOCK_SIZE", try allocPrint(b.allocator, "{}ull", .{opt}));

        if (b.option([]const u8, "null", "")) |opt|
            lib.root_module.addCMacro("VMA_NULL", opt);
        if (b.option([]const u8, "configuration_user_includes_h", "")) |opt|
            lib.root_module.addCMacro("VMA_CONFIGURATION_USER_INCLUDES_H", try allocPrint(b.allocator, "\"{s}\"", .{opt}));
    }

    b.installArtifact(lib);
}
