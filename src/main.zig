const std = @import("std");
const mvzr = @import("mvzr");
const parser = @import("parser");

const data = struct {
    file: []const u8,
    regex: ?[]const u8 = null,
};

pub fn main(init: std.process.Init) !void {
    const minimal = init.minimal;
    const args = minimal.args;
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var argIterator = try args.iterateAllocator(allocator);

    while (argIterator.next()) |arg| {
        std.debug.print("{s}\n", .{arg});
    }

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    try parser.printFile(io, allocator, "test.txt", "woa");
    std.debug.print("Test", .{});
}
