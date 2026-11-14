// ARM64v8 Shell for macOS
// Built-in: pwd

.extern get_current_path

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl builtin_pwd

// Built-in: pwd
// Implementation using shared get_current_path function
builtin_pwd:
    // Establish frame and save callee-saved registers
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!

    // Call get_current_path with pwd_buffer
    adrp    x0, pwd_buffer@PAGE
    add     x0, x0, pwd_buffer@PAGEOFF
    bl      get_current_path

    // Check if get_current_path failed
    cmp     x0, #0
    bne     pwd_display_error

    // Calculate path length using strlen
    adrp    x19, pwd_buffer@PAGE
    add     x19, x19, pwd_buffer@PAGEOFF
    mov     x20, x19              // x20 = buffer pointer

pwd_strlen_loop:
    ldrb    w21, [x20], #1        // load byte, increment pointer
    cbnz    w21, pwd_strlen_loop  // continue if not null

    // Back up from position after null terminator to null terminator
    sub     x20, x20, #1
    // Calculate string length (excluding null terminator)
    sub     x20, x20, x19

    // Print the path
    mov     x0, #1                // stdout
    mov     x1, x19               // buffer pointer
    mov     x2, x20               // length
    mov     x16, #4               // write syscall
    svc     #0x80

    // Print newline
    mov     x0, #1                // stdout
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #newline_len      // Newline length
    mov     x16, #4               // write syscall
    svc     #0x80

    mov     x0, xzr               // Return success
    b       pwd_epilogue

pwd_display_error:
    // Print error message
    mov     x0, #2                // stderr
    adrp    x1, pwd_error@PAGE
    add     x1, x1, pwd_error@PAGEOFF
    mov     x2, #pwd_error_len    // error message length
    mov     x16, #4               // write syscall
    svc     #0x80

    mov     x0, #1                // Return error

// Shared epilogue: restore registers and return
pwd_epilogue:
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

.section __DATA, __bss
.p2align 3

// Buffer for storing the current working directory path
// PATH_MAX on macOS is 1024
pwd_buffer:
    .space 1024

.section __TEXT, __cstring

newline:
    .asciz "\n"
    .set newline_len, . - newline

pwd_error:
    .asciz "pwd: error getting cwd\n"
    .set pwd_error_len, . - pwd_error
