const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "mask-pii",
        .root_source_file = .{ .path = "src/mask_pii.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    _ = b.addModule("mask-pii", .{
        .root_source_file = .{ .path = "src/mask_pii.zig" },
    });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mask_pii.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
