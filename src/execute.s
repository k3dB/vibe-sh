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
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

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
    cmp     x0, #0
    beq     builtin_exit

    // Check for echo built-in
    mov     x0, x22
    bl      strcmp_echo
    cmp     x0, #0
    beq     builtin_echo_setup

    // Check for pwd built-in
    mov     x0, x22
    bl      strcmp_pwd
    cmp     x0, #0
    beq     builtin_pwd

    // Check for cd built-in
    mov     x0, x22
    bl      strcmp_cd
    cmp     x0, #0
    beq     builtin_cd_setup

    // Not a built-in, execute external command
    mov     x0, x19
    mov     x1, x20
    bl      execute_external

execute_done:
    // Epilogue
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
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
    // Print newline before exit
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4         // write syscall
    svc     #0x80

    // Exit with code 0
    mov     x0, #0
    mov     x16, #1         // exit syscall
    svc     #0x80           // Exits the process, no code runs after this

// Built-in: echo
// x0 = token array, x1 = token count
builtin_echo:
    // Use temporary registers
    // x2 = current token index
    // x3 = token pointer
    // x4 = token length

    mov     x2, #1          // Start from token 1 (skip "echo")

builtin_echo_loop:
    cmp     x2, x1
    bge     builtin_echo_done

    // Get token pointer
    ldr     x3, [x0, x2, lsl #3]

    // Calculate token length
    mov     x0, x3
    bl      strlen
    mov     x4, x0

    // Print token
    mov     x0, #1
    mov     x1, x3
    mov     x2, x4
    mov     x16, #4         // write syscall
    svc     #0x80

    // Print space if not last token
    add     x5, x2, #1
    cmp     x5, x1
    bge     builtin_echo_next

    mov     x0, #1
    adrp    x1, space@PAGE
    add     x1, x1, space@PAGEOFF
    mov     x2, #1
    mov     x16, #4         // write syscall
    svc     #0x80

builtin_echo_next:
    add     x2, x2, #1
    b       builtin_echo_loop

builtin_echo_done:
    // Print newline
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4         // write syscall
    svc     #0x80
    b       execute_done

// Built-in: pwd
builtin_pwd:
    // For now, just print a placeholder since getcwd is not a direct syscall on macOS
    // In a real implementation, we'd call the libc getcwd function
    mov     x0, #1
    adrp    x1, pwd_placeholder@PAGE
    add     x1, x1, pwd_placeholder@PAGEOFF
    mov     x2, #18
    mov     x16, #4         // write syscall
    svc     #0x80

    // Print newline
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
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
    mov     x0, #1
    adrp    x1, cd_error@PAGE
    add     x1, x1, cd_error@PAGEOFF
    mov     x2, #26
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
    mov     x0, #1
    adrp    x1, cd_error@PAGE
    add     x1, x1, cd_error@PAGEOFF
    mov     x2, #29
    mov     x16, #4         // write syscall
    svc     #0x80

.section __TEXT, __cstring

newline:
    .asciz "\n"
space:
    .asciz " "
pwd_placeholder:
    .asciz "/current/directory"
pwd_error:
    .asciz "pwd: error getting cwd\n"
cd_error:
    .asciz "cd: error changing directory\n"
