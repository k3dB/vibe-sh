// ARM64v8 Shell for macOS
// Error handling module - execution error messages

.section __DATA, __bss
.globl error_buffer
.p2align 3
error_buffer:
    .space 256

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl handle_exec_error

// Handle execution errors - display appropriate error message to stdout
// x0 = error code (Darwin errno)
// x1 = command name (argv[0])
// returns x0 = exit status code
handle_exec_error:
    // Prologue
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!

    mov     x19, x0                // Save error code
    mov     x20, x1                // Save command name

    // Build error message in buffer: "<command>: <error message>\n"
    adrp    x8, error_buffer@PAGE  // Use volatile register for buffer pointer
    add     x8, x8, error_buffer@PAGEOFF

    // Copy command name to buffer
    mov     x9, x20                // src (command name)
    mov     x10, x8                // dst (buffer)

copy_command_loop:
    ldrb    w11, [x9], #1
    cbz     w11, copy_command_done
    strb    w11, [x10], #1
    b       copy_command_loop

copy_command_done:
    // Calculate command name length: (x10 - x8)
    sub     x11, x10, x8

    // Append ": "
    mov     w12, #':'
    strb    w12, [x10], #1
    mov     w12, #' '
    strb    w12, [x10], #1

    // Save command name length in x12
    mov     x12, x11

    // Determine which error message to append and calculate length
    cmp     x19, #2               // ENOENT
    beq     append_noent
    cmp     x19, #13              // EACCES
    beq     append_eacces
    cmp     x19, #8               // ENOEXEC
    beq     append_enoexec
    b       append_unknown

append_noent:
    adrp    x9, error_msg_noent@PAGE
    add     x9, x9, error_msg_noent@PAGEOFF
    mov     x2, x12
    ldr     x13, =error_msg_noent_len
    add     x2, x2, x13
    add     x2, x2, #2
    b       copy_error_msg

append_eacces:
    adrp    x9, error_msg_eacces@PAGE
    add     x9, x9, error_msg_eacces@PAGEOFF
    mov     x2, x12
    ldr     x13, =error_msg_eacces_len
    add     x2, x2, x13
    add     x2, x2, #2
    b       copy_error_msg

append_enoexec:
    adrp    x9, error_msg_enoexec@PAGE
    add     x9, x9, error_msg_enoexec@PAGEOFF
    mov     x2, x12
    ldr     x13, =error_msg_enoexec_len
    add     x2, x2, x13
    add     x2, x2, #2
    b       copy_error_msg

append_unknown:
    adrp    x9, error_msg_unknown@PAGE
    add     x9, x9, error_msg_unknown@PAGEOFF
    mov     x2, x12
    ldr     x13, =error_msg_unknown_len
    add     x2, x2, x13
    add     x2, x2, #2

copy_error_msg:
    // Copy error message to buffer
copy_msg_loop:
    ldrb    w11, [x9], #1
    cbz     w11, copy_msg_done
    strb    w11, [x10], #1
    b       copy_msg_loop

copy_msg_done:
write_error:
    // Write the error message to stdout
    mov     x0, #1                // stdout
    mov     x1, x8                // buffer pointer
    mov     x16, #4               // write syscall
    svc     #0x80

    // Determine exit status based on error code
    cmp     x19, #2               // ENOENT
    beq     exit_noent
    cmp     x19, #13              // EACCES
    beq     exit_eacces
    cmp     x19, #8               // ENOEXEC
    beq     exit_eacces

    // Default exit status
    mov     x0, #126
    b       handle_exec_error_end

exit_noent:
    mov     x0, #127
    b       handle_exec_error_end

exit_eacces:
    mov     x0, #126

handle_exec_error_end:
    // Epilogue
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

.section __TEXT, __cstring

error_msg_noent:
    .asciz "command not found\n"
.set error_msg_noent_len, . - error_msg_noent

error_msg_eacces:
    .asciz "permission denied\n"
.set error_msg_eacces_len, . - error_msg_eacces

error_msg_enoexec:
    .asciz "exec format error\n"
.set error_msg_enoexec_len, . - error_msg_enoexec

error_msg_unknown:
    .asciz "execution error\n"
.set error_msg_unknown_len, . - error_msg_unknown
