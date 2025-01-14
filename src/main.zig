const std = @import("std");

//lord have mercy right stdout everytime I have to use it is actually hell
const stdout = std.io.getStdOut();
const stdin = std.io.getStdIn();

//number of total possible characters
const NO_OF_CHARS: u32 = 256;

pub fn main() !void {
    //check if I have the args needed, could be cleaner and will be soon but yeah
    if (std.os.argv.len <= 1) {
        try std.io.getStdErr().writer().print("Error: do not have enough Args, please see help command\n", .{});
        return;
    }
    const path_null_terminated: [*:0]u8 = std.os.argv[1];

    var count: u32 = 0;

    if (std.os.argv.len <= 2) {
        var reader = stdin.reader();
        const pat: [:0]const u8 = std.mem.span(path_null_terminated);
        var buf: [1000]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            count += 1;
            try search(line, pat, count);
        }
    } else {
        const pat_null_terminated: [*:0]u8 = std.os.argv[2];
        const path: [:0]const u8 = std.mem.span(path_null_terminated);
        const pat: [:0]const u8 = std.mem.span(pat_null_terminated);
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        var bufReader = std.io.bufferedReader(file.reader());
        var inStream = bufReader.reader();

        var buf: [1024]u8 = undefined;
        while (try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            count += 1;
            try search(line, pat, count);
        }
    }
    return;
}

pub fn badCharHeuristic(str: []const u8, size: u64, badchar: *[NO_OF_CHARS]u16) void {
    var i: u16 = 0;
    while (i < NO_OF_CHARS) : (i += 1) {
        badchar[i] = 0;
    }
    i = 0;
    while (i < size) : (i += 1) {
        badchar[str[i]] = i;
    }
}

pub fn search(str: []const u8, pat: []const u8, count: u32) !void {
    const m: i64 = @intCast(pat.len);
    const n: i64 = @intCast(str.len);

    var badchar: [NO_OF_CHARS]u16 = undefined;
    badCharHeuristic(pat, @intCast(m), &badchar);

    var s: i64 = 0;

    while (s <= (n - m)) {
        var j: i64 = m - 1;
        var idx: i64 = @intCast(j);
        //reducing index of j of pattern while character of pattern and text are matching at this shift s
        while (idx >= 0 and pat[@intCast(idx)] == str[@as(u64, @intCast(s + idx))]) {
            idx -= 1;
        }

        if (idx < 0) {
            try stdout.writer().print("{d}:{s} \n", .{ count, str });
            s += if (s + m < n) m - badchar[str[@as(u64, @intCast(s + m))]] else 1;
        } else {
            j = @intCast(idx);
            s += @intCast(@max(1, (idx) - badchar[str[@as(u64, @intCast(s + j))]]));
        }
    }
}
