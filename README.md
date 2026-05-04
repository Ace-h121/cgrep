# cgrep

A fast, ergonomic command-line tool that combines `cat` and `grep` into a single command. Instead of piping one into the other, just run `cgrep`.

> Written in [Zig](https://ziglang.org/) — despite the name.

---

## Why cgrep?

If you've ever typed `cat /some/long/path/to/file | grep some_pattern`, you know the friction. `cgrep` collapses that into one command and also works as a drop-in replacement for `grep` when reading from stdin, as well as a drop-in replacement for cat when just a file is passed.

---

## Installation

**Requirements:** [Zig](https://ziglang.org/download/) installed on your system.

```sh
git clone https://github.com/Ace-h121/cgrep.git
cd cgrep
zig build
```

This produces a binary at `./zig-out/bin/cgrep`. Add it to your `$PATH` to use it anywhere:

```sh
# Example: move it to a directory already on your PATH
cp ./zig-out/bin/cgrep ~/.local/bin/
```

---

## Usage

`cgrep` has two modes — it figures out which one to use based on your arguments.

### Read from a file

```sh
cgrep /path/to/file pattern
```

Opens the file and searches for lines matching `pattern`.

### Read from stdin

```sh
some_command | cgrep pattern -g
```

Pass the `-g` flag (no file path) to read from stdin until EOF. This makes `cgrep` a direct replacement for `grep` in pipelines.

---

## Flags

| Flag | Description |
|------|-------------|
| `-g` | Read from stdin instead of a file |
| `-l` | Print line numbers alongside each match |
| `-c <color>` | Set a custom color for matched output |

---

## Examples

```sh
# Search a log file for errors
cgrep /var/log/syslog ERROR

# Filter output from another command
dmesg | cgrep usb -g

# Works just like grep in a pipe
cat notes.txt | cgrep TODO -g

# Show line numbers next to each match
cgrep /var/log/syslog ERROR -l

# Use a custom color for match output
cgrep /var/log/syslog ERROR -c red

# Combine flags: line numbers + custom color
cgrep notes.txt TODO -l -c blue
```

---


