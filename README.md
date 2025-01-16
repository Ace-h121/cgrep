# About 
This Project combines the bash commands `Cat` and `Grep`, Cat is used for printing a file out to standard out, and grep is used for pattern matching. Cgrep allows you to instead of typing `Cat /Path/To/File | grep pattern` simply just type `cgrep /Path/To/File pattern`
contrary to the name, cgrep is not written in c but in zig!
# Installtion
To build and compile the app, simply run `zig build` in the root directory of the project, and it will create a bin in ./zig-out/bin/ called cgrep. Simply add this executable to your $PATH, and its ready to go!
# Usage 
cgrep has to main ways to be used, reading from a file, and reading from stdin and reading from a file. Heres how they are used:
1. read from stdin: `cgrep pattern`, cgrep will infer that you want to read from stdin and will read until it sees EOF. This means that cgrep is a drop in replacement for grep in this way
2. read from file: `cgrep /path/to/file pattern`, cgrep will also infer that you want to read from a file, will open the file in a buffer and search for your pattern!

