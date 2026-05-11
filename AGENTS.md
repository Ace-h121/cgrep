# CGREP Repository

## Build & Test Commands

```bash
zig build                     # Build the binary
zig build test                # Run all tests
```

## Source Structure

- `src/main.zig` - Entry point: argument parsing, mode routing, color handling
- `src/parser.zig` - File/stdin reading, regex matching, output formatting
- `mvzr` - External regex library (runtime-compiled pattern matcher)
- `zig-pkg/` - `mvzr` dependency

## Quirks & Gotchas

- Uses `std.Io.File` with streaming writes (not `std.io.getStdOut`)
- Tests embedded inline in source files (no separate test directory)
- Exit code `1` = file not found; `5` = unknown parser error
- Custom error `ArgsError.NoColor` for invalid color names
- Empty pattern on stdin will exit silently; guard at `parser.zig:82-83` prevents mvzr panic

## How to Run a Single Test

```bash
# Parser tests
./.zig-cache/o/<hash>/test

# Main module tests
./.zig-cache/o/<hash>/test
```

The test runner auto-discovers all `test "name"` blocks in source files.

## Regex Behavior (mvzr)

- `.` matches newlines
- `$` after match allows newline; `^` must be at string start
