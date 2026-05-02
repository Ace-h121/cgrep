const std = @import("std");
const mvzr = @import("mvzr");
const parser = @import("parser");

pub fn main() !void {
    parser.printTest();
     std.debug.print("Test", .{});
}
