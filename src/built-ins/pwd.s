// ARM64v8 Shell for macOS
// Built-in: pwd

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl builtin_pwd

// Built-in: pwd
// Implementation using macOS syscalls (open and fcntl with F_GETPATH)
builtin_pwd:
    // Establish frame and save callee-saved registers
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    // Open current directory "." for getting path
    adrp    x0, dot_path@PAGE
    add     x0, x0, dot_path@PAGEOFF
    mov     x1, #0                // flags = O_RDONLY
    mov     x2, #0                // mode = 0
    mov     x16, #5               // open syscall
    svc     #0x80

    // Check if open failed
    cmp     x0, #-1
    beq     pwd_open_error

    // Save file descriptor in x19
    mov     x19, x0

    // Get path using fcntl with F_GETPATH
    mov     x0, x19               // fd
    mov     x1, #50               // F_GETPATH
    adrp    x2, pwd_buffer@PAGE   // buffer pointer
    add     x2, x2, pwd_buffer@PAGEOFF
    mov     x16, #92              // fcntl syscall
    svc     #0x80

    // Check if fcntl failed
    cmp     x0, #-1
    beq     pwd_fcntl_error

    // Close the file descriptor
    mov     x0, x19
    mov     x16, #6               // close syscall
    svc     #0x80

    // Calculate path length using strlen
    adrp    x20, pwd_buffer@PAGE
    add     x20, x20, pwd_buffer@PAGEOFF
    mov     x21, x20              // x21 = buffer pointer

pwd_strlen_loop:
    ldrb    w22, [x21], #1        // load byte, increment pointer
    cbnz    w22, pwd_strlen_loop  // continue if not null

    // Back up from position after null terminator to null terminator
    sub     x21, x21, #1
    // Calculate string length (excluding null terminator)
    sub     x21, x21, x20

    // Print the path
    mov     x0, #1                // stdout
    mov     x1, x20               // buffer pointer
    mov     x2, x21               // length
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

pwd_open_error:
    // Print error message
    mov     x0, #2                // stderr
    adrp    x1, pwd_error@PAGE
    add     x1, x1, pwd_error@PAGEOFF
    mov     x2, #pwd_error_len    // error message length
    mov     x16, #4               // write syscall
    svc     #0x80

    mov     x0, #1                // Return error
    b       pwd_epilogue

pwd_fcntl_error:
    // Close the file descriptor before returning error
    mov     x0, x19
    mov     x16, #6               // close syscall
    svc     #0x80

    // Print error message
    mov     x0, #2                // stderr
    adrp    x1, pwd_error@PAGE
    add     x1, x1, pwd_error@PAGEOFF
    mov     x2, #pwd_error_len    // error message length
    mov     x16, #4               // write syscall
    svc     #0x80

    mov     x0, #1                // Return error
    b       pwd_epilogue

// Shared epilogue: restore registers and return
pwd_epilogue:
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
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

dot_path:
    .asciz "."

pwd_error:
    .asciz "pwd: error getting cwd\n"
    .set pwd_error_len, . - pwd_error
