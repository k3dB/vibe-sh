// ARM64v8 Shell for macOS
// External command execution module (fork/execve)

.section __DATA, __bss

.equ COMMAND_MAX, 1024

.globl wait_status
.p2align 3
wait_status:
    .space 8

.globl argv_buffer
.p2align 4
argv_buffer:
    .space 2048

.globl envp_buffer
.p2align 3
envp_buffer:
    .space 256

command_buffer:
    .space COMMAND_MAX

.section __TEXT, __text, regular, pure_instructions
.p2align 2

.globl execute_external

// Execute external command
// x0 = token array
// x1 = token count
// x2 = path value pointer

execute_external:
    stp     x29, x30, [sp, #-16]! // Prologue: save FP and LR
    mov     x29, sp
    stp     x19, x20, [sp, #-16]! // Save callee-saved registers
    stp     x21, x22, [sp, #-16]!

    mov     x19, x0               // tokens
    mov     x20, x1               // token count
    mov     x21, x2               // path value pointer

    mov     x16, #2               // fork syscall
    svc     #0x80

    cbz     x1, wait_for_child    // Darwin returns 0 in x1 for parent process
    cmp     x1, #1                // Darwin returns 1 in x1 for child process
    beq     exec_child

failure:
    mov     x0, #-1               // failure
    b       execute_external_end
success:
    mov     x0, #0                // success
execute_external_end:
    ldp     x21, x22, [sp], #16   // Restore callee-saved registers
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16   // Restore FP and LR
    ret

wait_for_child:
    adrp    x1, wait_status@PAGE
    add     x1, x1, wait_status@PAGEOFF
    mov     x2, #0                // options
    mov     x3, #0                // rusage
    mov     x16, #7               // wait4 syscall
    svc     #0x80

    cmp     x0, #0                // check if wait4 failed
    blt     failure

    adrp    x1, wait_status@PAGE  // Load and check wait status
    add     x1, x1, wait_status@PAGEOFF
    ldr     w1, [x1]

    and     w2, w1, #0x7f         // Check if terminated by signal
    cbnz    w2, failure

    lsr     w2, w1, #8            // Extract exit status
    and     w2, w2, #0xff         // Mask to 8 bits
    cbnz    w2, failure

    b       success
    // ^^^ End of parent code

exec_child:
    // Get executable path
    ldr     x0, [x19]             // executable path

    // Use argv_buffer for argv[]
    adrp    x1, argv_buffer@PAGE
    add     x1, x1, argv_buffer@PAGEOFF

    // Copy token pointers to argv_buffer
    mov     x10, x1               // dst
    mov     x11, x19              // src
    mov     x12, x20              // count

next_token:
    cbz     x12, token_copy_done

    ldr     x13, [x11], #8
    str     x13, [x10], #8

    subs    x12, x12, #1
    bne     next_token

token_copy_done:
    str     xzr, [x10]

    // Set up empty envp (array with single NULL pointer)
    adrp    x2, envp_buffer@PAGE
    add     x2, x2, envp_buffer@PAGEOFF
    str     xzr, [x2]             // envp[0] = NULL

    // execve(path, argv, environ)
    mov     x16, #59              // execve syscall
    svc     #0x80

    // execve failed - terminate child process with returned status

    // x0 already contains error code from execve
    ldr     x1, [x19]             // command name from tokens[0]
    bl      handle_exec_error     // Returns exit status code in x0

    mov     x16, #1               // exit syscall
    svc     #0x80
