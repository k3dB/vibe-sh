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

.globl command_buffer
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
    stp     x29, x30, [sp, #-16]! // prologue
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    stp     x23, x24, [sp, #-16]!

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
    ldp     x23, x24, [sp], #16   // epiplogue
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
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

    adrp    x1, wait_status@PAGE  // load and check wait status
    add     x1, x1, wait_status@PAGEOFF
    ldr     w1, [x1]

    and     w2, w1, #0x7f         // check if terminated by signal
    cbnz    w2, failure

    lsr     w2, w1, #8            // extract exit status
    and     w2, w2, #0xff         // mask to 8 bits
    cbnz    w2, failure

    b       success
    // ^^^ End of parent code

exec_child:
    // Get executable path
    ldr     x0, [x19]             // executable path
    mov     x22, x0               // save command name for later use

    // Initialize position pointer to NULL for first call
    mov     x23, #0               // current position in PATH

    // Set up argv and envp before the retry loop (they don't change)
    adrp    x10, argv_buffer@PAGE
    add     x10, x10, argv_buffer@PAGEOFF

    // Copy token pointers to argv_buffer
    mov     x11, x19              // src
    mov     x12, x20              // count

setup_argv_loop:
    cbz     x12, argv_copy_done

    ldr     x13, [x11], #8
    str     x13, [x10], #8

    subs    x12, x12, #1
    bne     setup_argv_loop

argv_copy_done:
    str     xzr, [x10]

    // Set up empty envp (array with single NULL pointer)
    adrp    x24, envp_buffer@PAGE
    add     x24, x24, envp_buffer@PAGEOFF
    str     xzr, [x24]            // envp[0] = NULL

path_retry_loop:
    mov     x0, x22               // command name
    mov     x1, x21               // PATH pointer
    mov     x2, x23               // current position
    bl      resolve_command_path  // get next path candidate

    // x0 = resolved path pointer (or NULL), x1 = updated position
    cbz     x0, all_paths_failed  // No more paths to try

    // Save updated position for next iteration
    mov     x23, x1

    // execve(path, argv, environ)
    mov     x0, x0                // resolved path
    adrp    x1, argv_buffer@PAGE
    add     x1, x1, argv_buffer@PAGEOFF
    mov     x2, x24               // envp
    mov     x16, #59              // execve syscall
    svc     #0x80

    // If we get here, execve failed - try next PATH component
    b       path_retry_loop

all_paths_failed:
    // All PATH components failed - fall through to error handling
    mov     x0, x22               // original command name for error message
    bl      handle_exec_error     // returns exit status code in x0

    mov     x16, #1               // exit syscall
    svc     #0x80
