// ARM64v8 Shell for macOS
// External command execution module (fork/execve)

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl execute_external

// Execute external command
// x0 = token array
// x1 = token count

// extern char **environ
//.extern _environ

execute_external:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]

    mov     x19, x0              // tokens
    mov     x20, x1              // token count

    mov     x16, #2              // fork
    svc     #0x80

    cmp     x0, #0
    blt     fork_failed
    beq     exec_child

    // Parent process
    mov     x19, x0              // save child PID

    // Reserve 16 bytes to preserve alignment
    sub     sp, sp, #16

    mov     x0, x19              // pid
    mov     x1, sp               // status
    mov     x2, #0               // options
    mov     x3, #0               // rusage

    mov     x16, #7              // wait4
    svc     #0x80

    add     sp, sp, #16

    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

exec_child:
    ldr     x0, [x19]            // executable path

    // Allocate argv[]
    add     x9, x20, #1          // argc + NULL
    lsl     x9, x9, #3           // bytes

    // Round up to 16-byte alignment
    add     x9, x9, #15
    bic     x9, x9, #15

    sub     sp, sp, x9

    mov     x1, sp               // argv

    // Copy pointers
    mov     x10, x1              // dst
    mov     x11, x19             // src
    mov     x12, x20             // count

copy_loop:
    cbz     x12, copy_done

    ldr     x13, [x11], #8
    str     x13, [x10], #8

    subs    x12, x12, #1
    bne     copy_loop

copy_done:
    str     xzr, [x10]

    // envp = _environ
    // adrp    x2, _environ@PAGE
    // ldr     x2, [x2, _environ@PAGEOFF]
    mov     x2, xzr              // NULL environment for now

    // execve(path, argv, environ)
    mov     x16, #59
    svc     #0x80

    // execve failed
    add     sp, sp, x9           // restore stack
    mov     x0, #127             // shell convention
    mov     x16, #1              // exit
    svc     #0x80

fork_failed:
    mov     x0, #-1
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
