// ARM64v8 Shell for macOS
// Path utilities module

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl is_absolute_or_relative

// Check if command name is an absolute or relative path
// x0 = command name
// returns x0 = 1 if contains '/', 0 if not
is_absolute_or_relative:
    mov     x1, x0                // Save command name in x1 for strchr
    mov     w0, #'/'              // Load '/' character to find
    bl      strchr                // Call strchr to find '/' in string

    // strchr returns pointer to '/' if found, or NULL (0) if not found
    cbnz    x0, is_absolute_or_relative_found
    mov     x0, #0                // Not found, return 0
    ret

is_absolute_or_relative_found:
    mov     x0, #1                // Found, return 1
    ret
