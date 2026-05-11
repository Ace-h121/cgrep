const std = @import("std");
const mvzr = @import("mvzr");
const parser = @import("parser");

const stderr = std.Io.File.stderr();
const stdout = std.Io.File.stdout();
const stdin = std.Io.File.stdin();

const Colors = struct {
    red: []const u8 = "\x1b[31m",
    black: []const u8 = "\x1b[30m",
    green: []const u8 = "\x1b[32m",
    brown: []const u8 = "\x1b[33m",
    blue: []const u8 = "\x1b[34m",
    purple: []const u8 = "\x1b[35m",
    cyan: []const u8 = "\x1b[36m",
    lightGray: []const u8 = "\x1b[37m",
};

const ColorEnum = enum {
    red,
    black,
    green,
    brown,
    blue,
    purple,
    cyan,
    gray,
};

const helpString =
\\Usage: cgrep <file> [pattern] [flags]
\\       cgrep <pattern> -g [flags]

\\Modes:
\\  cgrep <file>             Print file contents (cat mode)
\\  cgrep <file> <pattern>   Search file for pattern
\\  cgrep <pattern> -g       Search stdin for pattern
\\
\\Flags:
\\  -g          Read from stdin
\\  -l          Print line numbers alongside matches
\\  -c <color>  Set a custom color for matched output

\\Colors:
\\  red, black, green, brown, blue, purple, cyan, gray
\\
;
const ArgsError = error{NoColor};

const colors = Colors{};

const ProgramData = parser.ProgramData;

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
        if (std.mem.eql(u8, fileName, "-h") or std.mem.eql(u8, fileName, "--help")){
            data.isHelpMode = true;
        }
        data.file = fileName;
    } else {
        try stderr.writeStreamingAll(io, "Please pass an arg \n");
        std.process.exit(1);
    }

    if (argIterator.next()) |pattern| {
        if (std.mem.eql(u8, pattern, "-g") or std.mem.eql(u8, pattern, "--grep")) {
            data.isGrepMode = true;
        } else {
            data.regex = pattern;
        }
    }

    //This will be used to go through flags and such currently doesnt do much
    while (argIterator.next()) |arg| {
        handleArg(arg, &data, &argIterator) catch |err| switch (err) {
            ArgsError.NoColor => {
                try stderr.writeStreamingAll(io, "Warning: That color is not avaliable, using default\n");
            },
        };
    }

    if (data.isHelpMode) {
        try stdout.writeStreamingAll(io, helpString);
        std.process.exit(0);
    }

    if (data.regex == null and !data.isGrepMode) {
        parser.printFile(io, allocator, stdout, data) catch |err| switch (err) {
            error.FileNotFound => {
                try stderr.writeStreamingAll(io, "That File does not exist, or has incorrect Permissions\n");
                std.process.exit(1);
            },
            else => std.process.exit(5),
        };
    } else if (data.isGrepMode) {
        try parser.printPatternStdin(io, allocator, stdout, data, stdin);
    } else {
        parser.printPattern(io, allocator, stdout, data) catch |err| switch (err) {
            error.FileNotFound => {
                try stderr.writeStreamingAll(io, "That File does not exist, or has incorrect Permissions\n");
                std.process.exit(1);
            },
            else => std.process.exit(5),
        };
    }
}

fn handleArg(arg: []const u8, data: *ProgramData, iterator: *std.process.Args.Iterator) !void {
    if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
        data.*.isHelpMode = true;
    }
    if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--color")) {
        const color = iterator.*.next();
        data.color = try handleColorArg(color);
    }

    if (std.mem.eql(u8, arg, "-g") or std.mem.eql(u8, arg, "--grep")) {
        data.isGrepMode = true;
    }

    if (std.mem.eql(u8, arg, "-l") or std.mem.eql(u8, arg, "--line")) {
        data.isLineMode = true;
    }
}

fn handleColorArg(color: ?[]const u8) ![]const u8 {
    if (color) |c| {
        const t = std.meta.stringToEnum(ColorEnum, c);

        if (t == null) {
            return ArgsError.NoColor;
        }

        switch (t.?) {
            ColorEnum.red => return colors.red,
            ColorEnum.black => return colors.black,
            ColorEnum.blue => return colors.blue,
            ColorEnum.brown => return colors.brown,
            ColorEnum.cyan => return colors.cyan,
            ColorEnum.gray => return colors.lightGray,
            ColorEnum.green => return colors.green,
            ColorEnum.purple => return colors.purple,
        }
    } else {
        return ArgsError.NoColor;
    }
}

test "handleColorArg - valid colors" {
    try std.testing.expectEqualStrings("\x1b[31m", try handleColorArg("red"));
    try std.testing.expectEqualStrings("\x1b[32m", try handleColorArg("green"));
    try std.testing.expectEqualStrings("\x1b[34m", try handleColorArg("blue"));
    try std.testing.expectEqualStrings("\x1b[33m", try handleColorArg("brown"));
    try std.testing.expectEqualStrings("\x1b[35m", try handleColorArg("purple"));
    try std.testing.expectEqualStrings("\x1b[36m", try handleColorArg("cyan"));
    try std.testing.expectEqualStrings("\x1b[37m", try handleColorArg("gray"));
    try std.testing.expectEqualStrings("\x1b[30m", try handleColorArg("black"));
}

test "handleColorArg - invalid color returns error" {
    try std.testing.expectError(error.NoColor, handleColorArg("invalid"));
    try std.testing.expectError(error.NoColor, handleColorArg(null));
}
