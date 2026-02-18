# VulkanMemoryAllocator

This is [VulkanMemoryAllocator](https://gpuopen.com/vulkan-memory-allocator/),
packaged for the [Zig](https://ziglang.org/) build system.

## how to use

1. Add `VulkanMemoryAllocator` to the dependency list in `build.zig.zon`:

```sh
zig fetch --save git+https://github.com/johan0A/VulkanMemoryAllocator
```

2. Config `build.zig`:

```zig
const vma_dep = b.dependency("VulkanMemoryAllocator", .{
    .target = target,
    .optimize = optimize,
    .VMA_DYNAMIC_VULKAN_FUNCTIONS = true,
    .VMA_STATIC_VULKAN_FUNCTIONS = false,
});
root_module.linkLibrary(vma_dep.artifact("VulkanMemoryAllocator"));
// Installed headers along the VulkanMemoryAllocator artifact:
//   "vk_mem_alloc_config.h" generated configuration header that reflects the provided options, should be included before vk_mem_alloc.h
//   "vk_mem_alloc.h"
```
