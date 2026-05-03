const std = @import("std");
const Io = std.Io;
const openFile = std.fs.openFile();
const mzvr = @import("mvzr");

pub fn printFile(io: Io, allocator: std.mem.Allocator, str: []const u8, regex: []const u8) !void {
    const fileBuffer = try allocator.alloc(u8, 1024 * 4);

    const file = try std.Io.Dir.cwd().openFile(io, str, .{});
    var fileReader = file.reader(io, fileBuffer);
    var reader = &fileReader.interface;

    while (reader.takeDelimiterInclusive('\n')) |line| {
        const match = mzvr.match(line, regex);
        if (match) |m| {
            std.debug.print("{s}", .{m.slice});
        }
    } else |err| switch (err) {
        error.EndOfStream => {
            return;
        },
        else => return err,
    }
}
