// ARM64v8 Shell for macOS
// External command execution module (fork/execve)

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.global execute_external

// Execute external command
// x0 = token array
// x1 = token count
execute_external:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp

    mov     x19, x0         // token array
    mov     x20, x1         // token count

    // Fork the process
    mov     x16, #66        // fork syscall
    svc     #0x80

    // Check if we're in child process (x0 == 0)
    cmp     x0, #0
    beq     exec_child

    // Parent process: wait for child
    // Allocate space for status
    sub     sp, sp, #8
    mov     x1, sp          // status pointer

    // wait4 syscall
    mov     x0, #-1         // wait for any child
    mov     x2, #0          // options
    mov     x3, #0          // rusage
    mov     x16, #73        // wait4 syscall
    svc     #0x80

    add     sp, sp, #8
    ldp     x29, x30, [sp], #32
    ret

exec_child:
    // Prepare for execve
    // x0 = path (first token)
    ldr     x0, [x19]

    // x1 = argv - need to null-terminate the token array
    // The token array is at x19, we need to add a NULL at the end
    // Allocate space for argv array on stack (token count + 1 for NULL)
    mov     x22, x20        // token count
    add     x22, x22, #1    // +1 for NULL terminator
    lsl     x22, x22, #3    // multiply by 8 (pointer size)
    sub     sp, sp, x22
    mov     x1, sp          // x1 = argv array on stack

    // Copy token pointers to argv array
    mov     x22, x0         // save x0 (path)
    mov     x23, x1         // argv write pointer
    mov     x24, x19        // token array read pointer
    mov     x25, x20        // token count

copy_argv_loop:
    cmp     x25, #0
    beq     argv_copy_done

    ldr     x3, [x24], #8   // load token pointer, advance
    str     x3, [x23], #8   // store to argv, advance
    sub     x25, x25, #1
    b       copy_argv_loop

argv_copy_done:
    // Null-terminate argv
    str     xzr, [x23]

    // Restore x0 (path)
    mov     x0, x22

    // x2 = envp (NULL for now)
    mov     x2, #0

    // execve syscall
    mov     x16, #59        // execve syscall
    svc     #0x80

    // If execve fails, exit with error
    mov     x0, #1
    mov     x16, #1         // exit syscall
    svc     #0x80
