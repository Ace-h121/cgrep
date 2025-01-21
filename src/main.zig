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

    //TODO: Rename this!
    const path_null_terminated: [*:0]u8 = std.os.argv[1];

    var count: u32 = 0;

    //If you are only given a pattern, read from std in
    if (std.os.argv.len <= 2) {
        var reader = stdin.reader();
        const pat: [:0]const u8 = std.mem.span(path_null_terminated);
        var buf: [1000]u8 = undefined;
        //Print everyline that contains the pattern, pass the count so the line number is there as well
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            count += 1;
            try search(line, pat, count);
        }
        // If passed both the file and pattern to match by, open the file and search for the pattern
    } else {
        //TODO: Rename this too
        const pat_null_terminated: [*:0]u8 = std.os.argv[2];
        const path: [:0]const u8 = std.mem.span(path_null_terminated);
        const pat: [:0]const u8 = std.mem.span(pat_null_terminated);
        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            return err;
        };
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

//Preprocess the array pretty much. Pass the array as a pointer so you can mess with it
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

//Dude, this algorith still hurts my brain, I used it as its the algorithm that grep uses for pattern matching. It seems to look for groups of characters in arrays, or string. Splits the string up, looks to see if the first char matches and if it does it keeps going, if not, moves on.
pub fn search(str: []const u8, pat: []const u8, count: u32) !void {
    const patLen: i64 = @intCast(pat.len);
    const strLen: i64 = @intCast(str.len);

    var badchar: [NO_OF_CHARS]u16 = undefined;
    badCharHeuristic(pat, @intCast(patLen), &badchar);

    var shift: i64 = 0;

    while (shift <= (strLen - patLen)) {
        var idx: i64 = patLen - 1;
        //reducing index of pattern while character of pattern and text are matching at this shift s
        while (idx >= 0 and pat[@intCast(idx)] == str[@as(u64, @intCast(shift + idx))]) {
            idx -= 1;
        }

        if (idx < 0) {
            try stdout.writer().print("{d}:{s} \n", .{ count, str });
            shift += if (shift + patLen < strLen) patLen - badchar[str[@as(u64, @intCast(shift + patLen))]] else 1;
        } else {
            shift += @intCast(@max(1, (idx) - badchar[str[@as(u64, @intCast(shift + idx))]]));
        }
    }
}
