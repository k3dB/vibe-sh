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
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     x19, x0         // x19 = token array
    mov     x20, x1         // x20 = token count
    mov     x21, #0         // x21 = current token index

print_simple_loop:
    cmp     x21, x20
    bge     print_simple_done

    // Get token pointer
    ldr     x1, [x19, x21, lsl #3]

    // Calculate token length
    bl      strlen
    mov     x2, x0

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
    ret

.section __DATA, __data
.p2align 2

newline:
    .asciz "\n"

// Print a number
// x0 = number to print
print_number:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp

    // Save callee-saved registers we'll use
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    sub     sp, sp, #32
    mov     x19, sp         // Buffer for number string

    cmp     x0, #0
    beq     print_zero

    mov     x20, #0         // Digit count
    mov     x21, #10        // Divisor

div_loop:
    cmp     x0, #0
    beq     div_done

    udiv    x2, x0, x21
    msub    x3, x2, x21, x0 // x3 = remainder
    add     x3, x3, #48     // Convert to ASCII
    strb    w3, [x19, x20]
    add     x20, x20, #1
    mov     x0, x2
    b       div_loop

div_done:
    // Save digit count
    mov     x22, x20

    // Reverse the digits
    mov     x1, #0
    sub     x20, x20, #1

reverse_loop:
    cmp     x1, x20
    bge     reverse_done

    ldrb    w2, [x19, x1]
    ldrb    w3, [x19, x20]
    strb    w3, [x19, x1]
    strb    w2, [x19, x20]

    add     x1, x1, #1
    sub     x20, x20, #1
    b       reverse_loop

reverse_done:
    // Print the number
    mov     x0, #1
    mov     x1, x19
    mov     x2, x22         // Use the saved digit count
    mov     x16, #4
    svc     #0x80

    // Restore callee-saved registers (sp is still at -80 from frame)
    ldp     x21, x22, [sp, #64]
    ldp     x19, x20, [sp, #48]
    add     sp, sp, #32
    ldp     x29, x30, [sp], #48
    ret

print_zero:
    mov     x0, #1
    mov     x1, x19
    strb    wzr, [x19]
    mov     w2, #48
    strb    w2, [x19]
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

    // Restore callee-saved registers (sp is still at -80 from frame)
    ldp     x21, x22, [sp, #64]
    ldp     x19, x20, [sp, #48]
    add     sp, sp, #32
    ldp     x29, x30, [sp], #48
    ret
