// ARM64v8 Shell for macOS
// I/O utilities module

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.global print_tokens_simple
.global print_number

// Print parsed tokens for debugging (simple version without indices)
// x0 = token array
// x1 = token count
print_tokens_simple:
    // Use callee-saved registers to preserve state across strlen calls
    // x19 = token array
    // x20 = token count
    // x21 = current token index
    stp     x19, x20, [sp, #-16]!
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     x19, x0         // x19 = token array
    mov     x20, x1         // x20 = token count
    mov     x21, #0         // x21 = current token index

print_simple_loop:
    cmp     x21, x20
    bge     print_simple_done

    // Get token pointer
    ldr     x0, [x19, x21, lsl #3]

    // Calculate token length
    bl      strlen
    mov     x2, x0
    mov     x1, x0         // Restore token pointer (strlen clobbers x0)
    ldr     x1, [x19, x21, lsl #3]

    // Print token
    mov     x0, #1
    mov     x16, #4
    svc     #0x80

    // Print newline
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

    add     x21, x21, #1
    b       print_simple_loop

print_simple_done:
    ldp     x29, x30, [sp], #16
    ldp     x19, x20, [sp], #16
    ret

.section __DATA, __data
.p2align 2

newline:
    .asciz "\n"

// Print a number
// x0 = number to print
print_number:
    // Use stack for buffer, so need prologue/epilogue
    // Use temporary registers since no function calls
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp

    sub     sp, sp, #32
    mov     x1, sp         // Buffer for number string

    cmp     x0, #0
    beq     print_zero

    mov     x2, #0          // Digit count
    mov     x3, #10        // Divisor

div_loop:
    cmp     x0, #0
    beq     div_done

    udiv    x4, x0, x3
    msub    x5, x4, x3, x0 // x5 = remainder
    add     x5, x5, #48     // Convert to ASCII
    strb    w5, [x1, x2]
    add     x2, x2, #1
    mov     x0, x4
    b       div_loop

div_done:
    // Save digit count
    mov     x6, x2

    // Reverse the digits
    mov     x3, #0
    sub     x2, x2, #1

reverse_loop:
    cmp     x3, x2
    bge     reverse_done

    ldrb    w4, [x1, x3]
    ldrb    w5, [x1, x2]
    strb    w5, [x1, x3]
    strb    w4, [x1, x2]

    add     x3, x3, #1
    sub     x2, x2, #1
    b       reverse_loop

reverse_done:
    // Print the number
    mov     x0, #1
    mov     x2, x6         // Use the saved digit count
    mov     x16, #4
    svc     #0x80

    add     sp, sp, #32
    ldp     x29, x30, [sp], #32
    ret

print_zero:
    mov     x0, #1
    strb    wzr, [x1]
    mov     w2, #48
    strb    w2, [x1]
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

    add     sp, sp, #32
    ldp     x29, x30, [sp], #32
    ret
