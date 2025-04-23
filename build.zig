const std = @import("std");
const Compile = std.Build.Step.Compile;
const Target = std.Build.ResolvedTarget;
const Optimize = std.builtin.OptimizeMode;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options = b.addOptions();
    const vulkan = b.option(bool, "vulkan", "Include the vulkan header and associated files") orelse false;
    options.addOption(bool, "vulkan", vulkan);
    const error_check = b.option(bool, "error_check", "Have Zig handle errors for you") orelse true;
    options.addOption(bool, "error_check", error_check);

    const glfw = b.dependency("glfw", .{
        .target = target,
        .optimize = optimize,
        .include_src = true,
    });

    // Add module
    const mod = b.addModule("rlfw", .{
        .root_source_file = b.path("src/module.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.linkLibrary(glfw.artifact("glfw"));
    mod.addOptions("glfw_options", options);

    // Tests
    const tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.root_module.addImport("rlfw", mod);
    tests.root_module.addOptions("build_options", options);
    tests.linkLibrary(glfw.artifact("glfw"));
    b.step("test", "Run glfw tests").dependOn(&b.addRunArtifact(tests).step);
}
