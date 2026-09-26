# ARM64 macOS Engineering Rules

This project targets:
- macOS
- Apple Silicon
- AArch64 / arm64
- Apple ABI
- clang assembler/toolchain

These rules are mandatory.

## 1. Register ownership

### Caller-saved / volatile

The following registers may be destroyed by a function call:

x0-x17
x30 (LR)

Treat these as temporary across BL/BLR and system calls.

### Callee-saved / non-volatile

A function that modifies these registers must restore them before returning:

x19-x28

The value observed by the caller after the function returns must be exactly
the value that existed when the function was entered.

Do NOT use x19-x28 as scratch registers merely because they are convenient.
They are not global variables that are shared across functions.

If a function needs persistent state across a BL/BLR or system call, prefer:
1. x19-x28 with a proper save/restore prologue, OR
2. stack storage, depending on lifetime and register pressure.

### Special registers

x18:
- RESERVED on Apple platforms.
- DO NOT USE.

x29:
- Frame pointer.
- Maintain a valid frame record when creating a normal stack frame.

x30:
- Link register.
- BL/BLR overwrite it.
- If this function makes a call and needs to return normally, preserve LR.

SP:
- Stack pointer.
- Keep it correctly aligned at call boundaries.
- Do not treat SP like an ordinary general-purpose register.

## 2. Function-call checklist

Before calling another function, determine:

- Which values must survive the call?
- Which registers contain those values?
- Are those registers caller-saved?
- If so, where are the values being preserved?
- Does this function itself need to preserve x19-x28?
- Is the stack correctly aligned?

After every BL/BLR, assume all caller-saved registers have been destroyed
unless the ABI/function contract says otherwise.

## 3. Prologue/epilogue

For a normal non-leaf function:

- Establish an appropriate frame.
- Preserve FP/LR as required.
- Preserve every x19-x28 register modified by the function.
- Restore them before returning.
- Restore SP exactly.

Do not invent a prologue/epilogue pattern.


## 4. Function return values

Follow the Apple ARM64 calling convention.

For ordinary integer/pointer returns:
- x0 / w0

Do not assume that a value remains in an argument register after a function call.

## 5. Assembly style

Prefer:

- clear register roles
- short functions
- explicit comments about persistent values
- simple prologues/epilogues
- named constants/macros where useful

Avoid clever register reuse unless it has a measurable benefit.

## 6. Function visibility

Make functions global only when necessary:

- Global functions: Only declare a function as global if it needs to be called
  from another file.
- Local functions: Use when the function is only used within its defining file
- Reusability: If function could be reused, consider moving it to a separate
  file. It will need to be global in that file.

Think of the `.globl` directive as exporting a function in JavaScript. You are
saying this function is called from function in another file.

## 7. Mandatory review before declaring completion

For every assembly function, verify:

[ ] x18 is never used
[ ] every modified x19-x28 is restored
[ ] FP/LR handling is correct
[ ] SP is restored
[ ] stack alignment is correct
[ ] caller-saved registers aren't assumed to survive BL/BLR
[ ] return register is correct
[ ] function visibility is appropriate (global only if called from other files)
[ ] assembly actually assembles
