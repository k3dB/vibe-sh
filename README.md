# Vibe Shell

A basic shell implementation in AArch64 (ARM64) assembly for macOS on Apple
Silicon. This is not intended to be a production shell, but rather a personal
learning exercise.

This project began as an experiment to test AI-assisted assembly programming.
While initial planning went well, implementing proper ARM64 register usage
required extensive manual intervention. The project continues with AI assistance
for planning and learning.

## Goal

The primary goal of this project is to learn how shells work while practicing
assembly programming. The implementation is intentionally written entirely in
ARM64 assembly, without higher-level languages or libraries.

The `main` branch is intended to remain stable. In-progress work is developed on
the volatile `vibe` branch, which may be force-pushed as development progresses.
When a feature on `vibe` reaches a stable state, its commit message is finalized
and main is rebased to include it.

## Code Constraints

- Only use ARM64 assembly for macOS
- Use system calls instead of library functions

## Usage Notes

The default (and currently only) prompt is `$$ `. The double dollar sign is
intentional to distinguish it from the standard `$` prompt of other shells. This
makes it easier to identify which shell is in use while doing manual testing.
There are no automated tests.

## Example Usage

```
% ./bin/shell
$$ echo Hello, World!
Hello, World!
$$ exit

%
```

## Current State

**Working Features:**
- Basic command parsing
- Basic built-in `echo` command functionality
- Built-in `exit` command

**Partially Implemented:**
- External command execution (PATH lookup in progress)
- Built-in `cd` command (see roadmap for missing functionality)

**Placeholder Implementation:**
- Built-in `pwd` command currently returns a hard-coded value

**Known Limitations:**
- PATH lookup for external commands is in progress
- Quoted strings not yet supported
- Variable expansion not yet supported
- `cd` does not yet support all expected shell behavior

## Roadmap

- [ ] Implement PATH lookup for external commands
- [ ] Handle `cd` (without arguments) to navigate to `~`
- [ ] Handle `cd -` for switching to previous directory
- [ ] Handle `.` and `..` in paths
- [ ] Handle `~` in paths
- [ ] Replace the hard-coded `pwd` command with a proper implementation
- [ ] Parse quoted strings
- [ ] Handle variable expansion

## Potential Future Enhancements

- [ ] Other built-in commands
- [ ] Handle command history
- [ ] Implement input/output redirection
- [ ] Implement pipes
- [ ] Implement background processes
- [ ] Implement environment variables (export, unset, etc.)

## System Requirements

- Apple Silicon Mac running macOS
- Xcode Command Line Tools (for the build tools `as`, `ld`, and `make`)

## Building

Build the project with:

```bash
make
```

`make` uses `as` for the assembler and `ld` for the linker.

To perform a clean rebuild:

```bash
make clean && make
```

## Running

```bash
./bin/shell
```
