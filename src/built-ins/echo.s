// ARM64v8 Shell for macOS
// Built-in: echo

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl builtin_echo

// Built-in: echo
// x0 = token array
// x1 = token count
builtin_echo:
    // x19 = token pointer
    // x20 = token count
    // x21 = current token index
    // x22 = first token (command name)

    // Prologue
    stp     x29, x30, [sp, #-16]! // preserve FP and LR
    mov     x29, sp               // set up new FP
    stp     x19, x20, [sp, #-16]! // preserve callee-saved registers
    stp     x21, x22, [sp, #-16]!

    mov     x20, x1               // save token count
    mov     x22, x0               // save token array base address
    mov     x21, #1               // start from token 1 (skip "echo")

builtin_echo_loop:
    cmp     x21, x20              // compare current index with token count
    bge     builtin_echo_done

    // Get token pointer
    ldr     x19, [x22, x21, lsl #3]

    // Calculate token length
    mov     x0, x19
    bl      strlen

    // Print token
    mov     x2, x0                // token length
    mov     x0, #1                // stdout
    mov     x1, x19               // token pointer
    mov     x16, #4               // write syscall
    svc     #0x80

    // Print token separator if not last token
    add     x5, x21, #1           // next token index
    cmp     x5, x20               // compare with token count
    bge     builtin_echo_next

    mov     x0, #1                // stdout
    adrp    x1, separator@PAGE
    add     x1, x1, separator@PAGEOFF
    mov     x2, #separator_len    // separator length
    mov     x16, #4               // write syscall
    svc     #0x80

builtin_echo_next:
    add     x21, x21, #1          // increment current token index
    b       builtin_echo_loop

builtin_echo_done:
    // Print newline
    mov     x0, #1                // stdout
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #newline_len      // newline length
    mov     x16, #4               // write syscall
    svc     #0x80

    mov     x0, xzr               // return success
    
    // Epilogue
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

.section __TEXT, __cstring

newline:
    .asciz "\n"
    .set newline_len, . - newline

separator:
    .asciz " "
    .set separator_len, . - separator
