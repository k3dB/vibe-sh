// ARM64v8 Shell for macOS
// Command execution module - built-in commands and dispatcher

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl execute_command
.globl builtin_exit
.globl builtin_echo
.globl builtin_pwd
.globl builtin_cd

// Constants
.equ PATH_MAX, 1024

// Execute command - check built-ins or execute external command
// x0 = token array
// x1 = token count
// x2 = path buffer
execute_command:
    // x19 = token array
    // x20 = token count
    // x21 = path buffer
    // x22 = command name

    // Prologue
    stp     x29, x30, [sp, #-16]! // Preserve FP and LR
    mov     x29, sp               // Set up new FP
    stp     x19, x20, [sp, #-16]! // Preserve callee-saved registers
    stp     x21, x22, [sp, #-16]!
    stp     x23, x24, [sp, #-16]! // For echo

    mov     x19, x0         // token array
    mov     x20, x1         // token count
    mov     x21, x2         // path buffer

    // Check if token count is 0 (empty line)
    cmp     x20, #0
    beq     execute_done

    // Get first token (command name)
    ldr     x22, [x19]

    // Check for exit built-in
    mov     x0, x22
    bl      strcmp_exit
    cbz     x0, builtin_exit

    // Check for echo built-in
    mov     x0, x22
    bl      strcmp_echo
    cbz     x0, builtin_echo_setup

    // Check for pwd built-in
    mov     x0, x22
    bl      strcmp_pwd
    cbz     x0, builtin_pwd

    // Check for cd built-in
    mov     x0, x22
    bl      strcmp_cd
    cbz     x0, builtin_cd_setup

    // Not a built-in, execute external command
    mov     x0, x19
    mov     x1, x20
    bl      execute_external

execute_done:
    mov     x0, xzr         // Return success
    mov     x1, xzr         // Clear exit flag
    // Epilogue
    ldp     x23, x24, [sp], #16 // Restore callee-saved registers
    ldp     x21, x22, [sp], #16 // Restore callee-saved registers
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16 // Restore FP and LR
    ret

builtin_echo_setup:
    mov     x0, x19
    mov     x1, x20
    bl      builtin_echo
    b       execute_done

builtin_cd_setup:
    mov     x0, x19
    mov     x1, x20
    mov     x2, x21
    bl      builtin_cd
    b       execute_done

// Built-in: exit
builtin_exit:
    mov     x0, xzr             // Return success
    mov     x1, #1              // Set exit flag
    // Epilogue
    ldp     x23, x24, [sp], #16 // Restore callee-saved registers
    ldp     x21, x22, [sp], #16 // Restore callee-saved registers
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16 // Restore FP and LR
    ret

// Built-in: echo
builtin_echo:
    // x20 = token count
    // x22 = first token (command name)
    // x23 = current token index
    // x24 = token pointer

    mov     x23, #1         // Start from token 1 (skip "echo")

builtin_echo_loop:
    cmp     x23, x20        // Compare current index with token count
    bge     builtin_echo_done

    // Get token pointer
    ldr     x24, [x0, x23, lsl #3]

    // Calculate token length
    mov     x0, x24
    bl      strlen

    // Print token
    mov     x2, x0          // Token length
    mov     x0, #1          // stdout
    mov     x1, x24         // Token pointer
    mov     x16, #4         // write syscall
    svc     #0x80

    // Print token separator if not last token
    add     x5, x23, #1     // Next token index
    cmp     x5, x20         // Compare with token count
    bge     builtin_echo_next

    mov     x0, #1          // stdout
    adrp    x1, separator@PAGE
    add     x1, x1, separator@PAGEOFF
    mov     x2, #1          // Separator length
    mov     x16, #4         // write syscall
    svc     #0x80

builtin_echo_next:
    add     x23, x23, #1    // Increment current token index
    b       builtin_echo_loop

builtin_echo_done:
    // Print newline
    mov     x0, #1          // stdout
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1          // Newline length
    mov     x16, #4         // write syscall
    svc     #0x80
    b       execute_done

// Built-in: pwd
builtin_pwd:
    // For now, just print a placeholder since getcwd is not a direct syscall on macOS
    // In a real implementation, we'd call the libc getcwd function
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
    b       execute_done

// Built-in: cd
// x0 = token array, x1 = token count, x2 = path buffer
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
    b       execute_done

cd_has_arg:
    // Get the path argument
    ldr     x0, [x0, #8]

    // chdir syscall
    mov     x16, #12        // chdir syscall number
    svc     #0x80

    // Check for error
    cmp     x0, #0
    beq     execute_done

    // Print error message
    mov     x0, #1          // stdout
    adrp    x1, cd_error@PAGE
    add     x1, x1, cd_error@PAGEOFF
    mov     x2, #29         // Error message length
    mov     x16, #4         // write syscall
    svc     #0x80

.section __TEXT, __cstring

newline:
    .asciz "\n"
separator:
    .asciz " "
pwd_placeholder:
    .asciz "/current/directory"
pwd_error:
    .asciz "pwd: error getting cwd\n"
cd_error:
    .asciz "cd: error changing directory\n"
