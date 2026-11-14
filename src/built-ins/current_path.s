// ARM64v8 Shell for macOS
// Current path utilities for built-ins

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl get_current_path

// Get the current working directory path
// x0 = buffer pointer (must be at least PATH_MAX bytes)
// Returns: x0 = 0 on success, non-zero on error
get_current_path:
    // Establish frame and save callee-saved registers
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!

    // Save buffer pointer in x19
    mov     x19, x0

    // Open current directory "." for getting path
    adrp    x0, dot_path@PAGE
    add     x0, x0, dot_path@PAGEOFF
    mov     x1, #0                // flags = O_RDONLY
    mov     x2, #0                // mode = 0
    mov     x16, #5               // open syscall
    svc     #0x80

    // Check if open failed
    cmp     x0, #-1
    beq     get_path_error

    // Save file descriptor in x20
    mov     x20, x0

    // Get path using fcntl with F_GETPATH
    mov     x0, x20               // fd
    mov     x1, #50               // F_GETPATH
    mov     x2, x19               // buffer pointer
    mov     x16, #92              // fcntl syscall
    svc     #0x80

    // Check if fcntl failed
    cmp     x0, #-1
    beq     get_path_close_error

    // Close the file descriptor
    mov     x0, x20
    mov     x16, #6               // close syscall
    svc     #0x80

    // Return success
    mov     x0, #0
    b       get_path_done

get_path_close_error:
    // Close the file descriptor before returning error
    mov     x0, x20
    mov     x16, #6               // close syscall
    svc     #0x80

get_path_error:
    // Return error
    mov     x0, #1

get_path_done:
    // Restore registers and return
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

.section __TEXT, __cstring

dot_path:
    .asciz "."
