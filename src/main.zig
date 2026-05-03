const std = @import("std");
const mvzr = @import("mvzr");
const parser = @import("parser");

const stderr = std.Io.File.stderr();

const ProgramData = struct {
    file: []const u8 = "",
    regex: ?[]const u8 = null,
};

pub fn main(init: std.process.Init) !void {
    var data: ProgramData = .{};
    const minimal = init.minimal;
    var arena = init.arena;

    const allocator = arena.allocator();

    const io = init.io;

    var argIterator = try minimal.args.iterateAllocator(allocator);

    //Needed to get rid of the program name arg
    _ = argIterator.next().?;

    if (argIterator.next()) |fileName| {
        data.file = fileName;
    }

    //This will be used to go through flags and such currently doesnt do much
    while (argIterator.next()) |arg| {
        //        std.debug.print("{s}\n", .{arg});
        _ = arg;
    }

    parser.printFile(io, allocator, data.file, "woa") catch |err| switch (err) {
        error.FileNotFound => {
            try stderr.writeStreamingAll(io, "That File Does not exist, or has incorrect Permissions\n");
            std.process.exit(1);
        },
        else => std.process.exit(5),
    };
}
