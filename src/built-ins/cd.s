// ARM64v8 Shell for macOS
// Built-in: cd

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl builtin_cd

// Built-in: cd
// x0 = token array
// x1 = token count
// x2 = path buffer
builtin_cd:
    // Check if argument provided
    cmp     x1, #1
    bgt     cd_has_arg

    // No argument, go to HOME directory
    // For now, just print error
    mov     x0, #1          // stdout
    adrp    x1, cd_error@PAGE
    add     x1, x1, cd_error@PAGEOFF
    mov     x2, #26         // Error message length
    mov     x16, #4         // write syscall
    svc     #0x80
    mov     x0, xzr         // Return success
    ret

cd_has_arg:
    // Get the path argument
    ldr     x0, [x0, #8]

    // chdir syscall
    mov     x16, #12        // chdir syscall
    svc     #0x80

    // Check for error
    cmp     x0, #0
    beq     cd_done

    // Print error message
    mov     x0, #1          // stdout
    adrp    x1, cd_error@PAGE
    add     x1, x1, cd_error@PAGEOFF
    mov     x2, #29         // Error message length
    mov     x16, #4         // write syscall
    svc     #0x80

cd_done:
    mov     x0, xzr         // Return success
    ret

.section __TEXT, __cstring

cd_error:
    .asciz "cd: error changing directory\n"
