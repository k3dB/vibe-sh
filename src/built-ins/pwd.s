// ARM64v8 Shell for macOS
// Built-in: pwd

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl builtin_pwd

// Built-in: pwd
// For now, just print a placeholder since getcwd is not a direct syscall on macOS
// In a real implementation, we'd call the libc getcwd function
builtin_pwd:
    mov     x0, #1          // stdout
    adrp    x1, pwd_placeholder@PAGE
    add     x1, x1, pwd_placeholder@PAGEOFF
    mov     x2, #18         // Placeholder length
    mov     x16, #4         // write syscall
    svc     #0x80

    // Print newline
    mov     x0, #1          // stdout
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1          // Newline length
    mov     x16, #4         // write syscall
    svc     #0x80

    mov     x0, xzr         // Return success
    ret

.section __TEXT, __cstring

newline:
    .asciz "\n"
pwd_placeholder:
    .asciz "/current/directory"
pwd_error:
    .asciz "pwd: error getting cwd\n"
