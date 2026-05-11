const std = @import("std");
const Io = std.Io;
const openFile = std.fs.openFile();
const mzvr = @import("mvzr");

pub const Colors = struct {
    red: []const u8 = "\x1b[31m",
    nc: []const u8 = "\x1b[0m",
};

pub const color: Colors = Colors{};

pub const ProgramData = struct {
    file: []const u8 = "",
    regex: ?[]const u8 = null,
    color: []const u8 = color.red,
    isHelpMode: bool = false,
    isGrepMode: bool = false,
    isLineMode: bool = false,
};

pub fn printFile(io: Io, allocator: std.mem.Allocator, stdout: std.Io.File, data: ProgramData) !void {
    const fileBuffer = try allocator.alloc(u8, 1024 * 4);

    const file = try std.Io.Dir.cwd().openFile(io, data.file, .{});
    var fileReader = file.reader(io, fileBuffer);
    var reader = &fileReader.interface;

    while (reader.takeDelimiterInclusive('\n')) |line| {
        try stdout.writeStreamingAll(io, line);
    } else |err| switch (err) {
        error.EndOfStream => {
            return;
        },
        else => return err,
    }
}

pub fn printPattern(io: Io, allocator: std.mem.Allocator, stdout: std.Io.File, data: ProgramData) !void {
    const fileBuffer = try allocator.alloc(u8, 1024 * 4);

    const file = try std.Io.Dir.cwd().openFile(io, data.file, .{});
    var fileReader = file.reader(io, fileBuffer);

    try printMatches(&fileReader, allocator, io, data, stdout);
}

pub fn printPatternStdin(io: Io, allocator: std.mem.Allocator, stdout: std.Io.File, data: ProgramData, stdin: std.Io.File) !void {
    const fileBuffer = try allocator.alloc(u8, 1024 * 4);

    const file = stdin;
    var fileReader = file.reader(io, fileBuffer);

    try printMatches(&fileReader, allocator, io, data, stdout);
}

pub fn getFormatedString(allocator: std.mem.Allocator, line: []const u8, match: mzvr.Match, data: ProgramData, lineNum: isize) ![]const u8 {
    var string: []const u8 = undefined;
    if (data.isLineMode) {
        string = try std.fmt.allocPrint(allocator, "{d}: {s}{s}{s}{s}{s}", .{
            lineNum,
            line[0..match.start],
            data.color,
            match.slice,
            color.nc,
            line[match.end..],
        });
    } else {
        string = try std.fmt.allocPrint(allocator, "{s}{s}{s}{s}{s}", .{
            line[0..match.start],
            data.color,
            match.slice,
            color.nc,
            line[match.end..],
        });
    }
    return string;
}

//we know the null accesses are safe due to checks in the main file
fn printMatches(fileReader: *Io.File.Reader, allocator: std.mem.Allocator, io: Io, data: ProgramData, stdout: std.Io.File) !void {
    const pattern = if (data.isGrepMode) data.file else data.regex.?;

    // Empty pattern would panic in mvzr - skip processing
    if (pattern.len == 0) return;

    var reader = &fileReader.interface;
    var i: i32 = 1;
    while (reader.takeDelimiterInclusive('\n')) |line| {
        const match = mzvr.match(line, pattern);
        if (match) |slice| {
            const string = try getFormatedString(allocator, line, slice, data, i);
            try stdout.writeStreamingAll(io, string);
        }
        i += 1;
    } else |err| switch (err) {
        error.EndOfStream => {
            return;
        },
        else => return err,
    }
}

test "getFormatedString without line numbers" {
    const allocator = std.testing.allocator;
    const data = ProgramData{};
    const line = "hello world";
    const match = (mzvr.match(line, "world") orelse return error.TestFailed);
    const result = try getFormatedString(allocator, line, match, data, 0);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("hello \x1b[31mworld\x1b[0m", result);
}

test "getFormatedString with line numbers" {
    const allocator = std.testing.allocator;
    var data = ProgramData{};
    data.isLineMode = true;
    const line = "hello world";
    const match = (mzvr.match(line, "world") orelse return error.TestFailed);
    const result = try getFormatedString(allocator, line, match, data, 42);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("42: hello \x1b[31mworld\x1b[0m", result);
}

test "getFormatedString with custom color" {
    const allocator = std.testing.allocator;
    var data = ProgramData{};
    data.color = "\x1b[32m";
    const line = "foo bar baz";
    const match = (mzvr.match(line, "bar") orelse return error.TestFailed);
    const result = try getFormatedString(allocator, line, match, data, 0);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("foo \x1b[32mbar\x1b[0m baz", result);
}

test "getFormatedString with match at start of line" {
    const allocator = std.testing.allocator;
    const data = ProgramData{};
    const line = "hello world";
    const match = (mzvr.match(line, "^hello") orelse return error.TestFailed);
    const result = try getFormatedString(allocator, line, match, data, 0);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("\x1b[31mhello\x1b[0m world", result);
}

test "getFormatedString with full line match" {
    const allocator = std.testing.allocator;
    const data = ProgramData{};
    const line = "hello";
    const match = (mzvr.match(line, "^hello$") orelse return error.TestFailed);
    const result = try getFormatedString(allocator, line, match, data, 0);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("\x1b[31mhello\x1b[0m", result);
}
