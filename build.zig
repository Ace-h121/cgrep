const std = @import("std");

pub fn build(b: *std.Build) void {
    const targetBuild = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mvzr = b.dependency("mvzr", .{
        .target = targetBuild,
        .optimize = optimize,
    });
    const mvzr_mod = mvzr.module("mvzr");

    const parser_mod = b.addModule("parser", .{ .root_source_file = b.path("src/parser.zig") });
    parser_mod.addImport("mvzr", mvzr_mod);

    const test_step = b.step("test", "Run unit tests");

    const test_srcs = [_]struct { src: []const u8, imports: []const struct { name: []const u8, mod: *std.Build.Module } }{
        .{ .src = "src/parser.zig", .imports = &.{.{ .name = "mvzr", .mod = mvzr_mod }} },
        .{ .src = "src/main.zig", .imports = &.{ .{ .name = "mvzr", .mod = mvzr_mod }, .{ .name = "parser", .mod = parser_mod } } },
    };

    for (test_srcs) |entry| {
        const test_exe = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(entry.src),
                .target = b.resolveTargetQuery(.{}),
            }),
        });
        for (entry.imports) |imp| {
            test_exe.root_module.addImport(imp.name, imp.mod);
        }
        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = targetBuild,
        .optimize = optimize,
    });
    exe_mod.addImport("mvzr", mvzr_mod);
    exe_mod.addImport("parser", parser_mod);

    const exe = b.addExecutable(.{
        .name = "cgrep",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);
}
