// ARM64v8 Shell for macOS
// Environment variable handling module

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl get_parent_path

// Get parent process environment and extract PATH
// Returns pointer to PATH string in x0, or NULL if not found
// Uses a static buffer to store the PATH
get_parent_path:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]

    // For now, use a hardcoded default PATH for macOS
    // This allows external commands to work while we debug sysctl
    adrp    x0, default_path@PAGE
    add     x0, x0, default_path@PAGEOFF
    
    // Copy default path to path_value buffer
    adrp    x19, path_value@PAGE
    add     x19, x19, path_value@PAGEOFF
    mov     x20, x0         // source

copy_default_path:
    ldrb    w0, [x20], #1
    strb    w0, [x19], #1
    cbnz    w0, copy_default_path

    // Return pointer to path_value
    adrp    x0, path_value@PAGE
    add     x0, x0, path_value@PAGEOFF

get_parent_done:
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

.section __TEXT, __cstring

default_path:
    .asciz "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

.section __DATA, __bss
.p2align 3

// Buffer to store PATH value
path_value:
    .space 4096
