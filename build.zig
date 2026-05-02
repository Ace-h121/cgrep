const std = @import("std");


const test_targets = [_]std.Target.Query{
    .{}, // native
    .{
        .cpu_arch = .x86_64,
        .os_tag = .windows
    },
};

pub fn build(b: *std.Build) void {
    const targetBuild = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});



    const test_step = b.step("test", "Run unit tests");

    testRunner("src/main.zig", b, test_step);
    testRunner("src/parser.zig", b, test_step);

    const parser_mod = b.addModule("parser", .{
        .root_source_file = b.path("src/parser.zig")
    });


    const mvzr = b.dependency("mvzr", .{
        .target = targetBuild,
        .optimize = optimize,
    });

    const mvzr_mod = mvzr.module("mvzr");

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

pub fn testRunner(src : []const u8, b :*std.Build, test_step: *std.Build.Step) void {
        for (test_targets) |target| {
        const unit_test = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(src),
                .target = b.resolveTargetQuery(target),
            }),
        });

        const run_unit_tests = b.addRunArtifact(unit_test);
        test_step.dependOn(&run_unit_tests.step);
    }

}
