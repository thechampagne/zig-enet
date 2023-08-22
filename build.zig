const std = @import("std");

const build_type = enum {
    static,
    shared,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enet_dep = b.dependency("libenet", .{
        .target = target,
        .optimize = optimize,
    });
    const enet = enet_dep.artifact("libenet");

    const lib_type = b.option(
        build_type,
        "build_type",
        "Whether you wish to build zig-enet as a static or shared library.",
    ) orelse .static;

    const lib: *std.Build.Step.Compile = switch (lib_type) {
        .static => b.addStaticLibrary(.{
            .name = "zig-enet",
            .root_source_file = .{ .path = "src/enet.zig" },
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .shared => b.addSharedLibrary(.{
            .name = "zig-enet",
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    };
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
