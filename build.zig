const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enet_dep = b.dependency("libenet", .{
        .target = target,
        .optimize = optimize,
    });
    const enet = enet_dep.artifact("libenet");

    const lib = b.addStaticLibrary(.{
        .name = "zig-enet",
        .root_source_file = .{ .path = "src/enet.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib.linkLibrary(enet);
    lib.installLibraryHeaders(enet);
    lib.addIncludePath(.{ .path = "." });

    b.installArtifact(lib);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tests.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    main_tests.linkLibrary(enet);
    main_tests.installLibraryHeaders(enet);

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
