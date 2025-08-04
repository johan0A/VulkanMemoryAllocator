# VulkanMemoryAllocator

This is [VulkanMemoryAllocator](https://gpuopen.com/vulkan-memory-allocator/),
packaged for the [Zig](https://ziglang.org/) build system.

## how to use

1. Add `VulkanMemoryAllocator` to the dependency list in `build.zig.zon`: 

```sh
zig fetch --save git+https://github.com/johan0A/VulkanMemoryAllocator#0.1.1+3.3.0
```

2. Config `build.zig`:

```zig
...
const vma_dep = b.dependency("VulkanMemoryAllocator", .{
    .target = target,
    .optimize = optimize,
});
your_compilation.linkLibrary("vma", vma_dep.artifact("VulkanMemoryAllocator"));
...
```
