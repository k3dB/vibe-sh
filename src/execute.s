// ARM64v8 Shell for macOS
// Command execution module - built-in commands and dispatcher

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.global execute_command
.global builtin_exit
.global builtin_echo
.global builtin_pwd
.global builtin_cd

// Constants
.equ PATH_MAX, 1024

// Execute command - check built-ins or execute external command
// x0 = token array
// x1 = token count
// x2 = path buffer
execute_command:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp

    // Save arguments
    mov     x19, x0         // token array
    mov     x20, x1         // token count
    mov     x21, x2         // path buffer

    // Check if token count is 0 (empty line)
    cmp     x20, #0
    beq     execute_done

    // Get first token (command name)
    ldr     x0, [x19]

    // Check for exit built-in
    bl      strcmp_exit
    cmp     x0, #0
    beq     builtin_exit

    // Reload command name for next comparison
    ldr     x0, [x19]

    // Check for echo built-in
    bl      strcmp_echo
    cmp     x0, #0
    beq     builtin_echo

    // Reload command name for next comparison
    ldr     x0, [x19]

    // Check for pwd built-in
    bl      strcmp_pwd
    cmp     x0, #0
    beq     builtin_pwd

    // Reload command name for next comparison
    ldr     x0, [x19]

    // Check for cd built-in
    bl      strcmp_cd
    cmp     x0, #0
    beq     builtin_cd

    // Not a built-in, execute external command
    mov     x0, x19
    mov     x1, x20
    //bl      execute_external

execute_done:
    ldp     x29, x30, [sp], #32
    ret

// Built-in: exit
builtin_exit:
    // Print newline before exit
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

    // Exit with code 0
    mov     x0, #0
    mov     x16, #1         // exit syscall
    svc     #0x80

// Built-in: echo
// x19 = token array, x20 = token count
builtin_echo:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // Start from token 1 (skip "echo")
    mov     x22, #1

builtin_echo_loop:
    cmp     x22, x20
    bge     builtin_echo_done

    // Get token pointer
    ldr     x1, [x19, x22, lsl #3]

    // Calculate token length
    mov     x0, x1
    bl      strlen
    mov     x2, x0

    // Print token
    mov     x0, #1
    mov     x16, #4
    svc     #0x80

    // Print space if not last token
    add     x3, x22, #1
    cmp     x3, x20
    bge     builtin_echo_next

    mov     x0, #1
    adrp    x1, space@PAGE
    add     x1, x1, space@PAGEOFF
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

builtin_echo_next:
    add     x22, x22, #1
    b       builtin_echo_loop

builtin_echo_done:
    // Print newline
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

    ldp     x29, x30, [sp], #16
    b       execute_done

// Built-in: pwd
// x21 = path buffer
builtin_pwd:
    // For now, just print a placeholder since getcwd is not a direct syscall on macOS
    // In a real implementation, we'd call the libc getcwd function
    mov     x0, #1
    adrp    x1, pwd_placeholder@PAGE
    add     x1, x1, pwd_placeholder@PAGEOFF
    mov     x2, #14
    mov     x16, #4
    svc     #0x80

    // Print newline
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

    b       execute_done

// Built-in: cd
// x19 = token array, x20 = token count, x21 = path buffer
builtin_cd:
    // Check if argument provided
    cmp     x20, #1
    bgt     cd_has_arg

    // No argument, go to HOME directory
    // For now, just print error
    mov     x0, #1
    adrp    x1, cd_error@PAGE
    add     x1, x1, cd_error@PAGEOFF
    mov     x2, #26
    mov     x16, #4
    svc     #0x80
    b       execute_done

cd_has_arg:
    // Get the path argument
    ldr     x0, [x19, #8]

    // chdir syscall
    mov     x16, #12        // chdir syscall number
    svc     #0x80

    // Check for error
    cmp     x0, #0
    beq     cd_done

    // Print error message
    mov     x0, #1
    adrp    x1, cd_error@PAGE
    add     x1, x1, cd_error@PAGEOFF
    mov     x2, #26
    mov     x16, #4
    svc     #0x80

cd_done:
    b       execute_done

.section __DATA, __data
.p2align 2

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
