// ARM64v8 Shell for macOS
// Basic I/O Loop with REPL and Command Parsing

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.global _main

// Buffer for user input
.equ INPUT_BUFFER_SIZE, 256
.equ MAX_TOKENS, 32
.equ MAX_TOKEN_LENGTH, 128

_main:
    // Save frame pointer and set up stack frame
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp

    // Allocate space for input buffer on stack
    sub     sp, sp, #INPUT_BUFFER_SIZE
    mov     x19, sp          // x19 = pointer to input buffer

    // Allocate space for token array (pointers to tokens)
    sub     sp, sp, #MAX_TOKENS * 8
    mov     x21, sp          // x21 = pointer to token array

repl_loop:
    // Display prompt "$$ "
    mov     x0, #1          // stdout
    adrp    x1, prompt@PAGE
    add     x1, x1, prompt@PAGEOFF
    mov     x2, #3          // length of "$$ "
    mov     x16, #4         // write syscall
    svc     #0x80

    // Read user input
    mov     x0, #0          // stdin
    mov     x1, x19         // buffer pointer
    mov     x2, #INPUT_BUFFER_SIZE
    mov     x16, #3         // read syscall
    svc     #0x80

    // Save the read length
    mov     x20, x0

    // Check for EOF (read returns 0)
    cmp     x20, #0
    beq     exit_shell

    // Check for error (read returns -1)
    cmp     x20, #-1
    beq     exit_shell

    // Null-terminate the input
    strb    wzr, [x19, x20]

    // Parse the command
    // x0 = input buffer, x1 = token array, returns x0 = token count
    mov     x0, x19
    mov     x1, x21
    bl      parse_command
    mov     x22, x0         // x22 = token count

    // For debugging, just print the token count
    mov     x0, x22
    bl      print_number

    // Print newline
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

    // Loop back to display prompt
    b       repl_loop

exit_shell:
    // Print newline before exit
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

    // Restore stack and exit
    add     sp, sp, #INPUT_BUFFER_SIZE
    add     sp, sp, #MAX_TOKENS * 8
    mov     x0, #0
    ldp     x29, x30, [sp], #32
    ret

// Parse command into space-delimited tokens
// x0 = input buffer (null-terminated)
// x1 = token array (array of pointers)
// returns x0 = number of tokens
parse_command:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     x19, x0         // x19 = input buffer
    mov     x20, x1         // x20 = token array
    mov     x21, #0         // x21 = token count
    mov     x22, #0         // x22 = in_token flag (0 = not in token, 1 = in token)

parse_loop:
    ldrb    w3, [x19]       // Load current character
    cmp     w3, #0
    beq     parse_done      // End of string

    cmp     w3, #32         // Check for space
    beq     parse_space

    // Not a space
    cmp     x22, #0
    bne     parse_continue  // Already in token

    // Start of new token
    str     x19, [x20, x21, lsl #3]  // Store token pointer
    add     x21, x21, #1  // Increment token count
    mov     x22, #1       // Set in_token flag

parse_continue:
    add     x19, x19, #1   // Move to next character
    b       parse_loop

parse_space:
    cmp     x22, #0
    beq     parse_skip     // Not in token, just skip

    // End of token - null-terminate it
    strb    wzr, [x19]     // Replace space with null
    mov     x22, #0        // Clear in_token flag

parse_skip:
    add     x19, x19, #1   // Move to next character
    b       parse_loop

parse_done:
    // Check if we were in a token at the end
    cmp     x22, #0
    beq     parse_return

    // Token was already stored, just need to ensure it's null-terminated
    // (it already is since we reached end of string)

parse_return:
    mov     x0, x21         // Return token count
    ldp     x29, x30, [sp], #16
    ret

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

// Calculate string length
// x0 = string pointer
// returns x0 = length
strlen:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     x1, x0
    mov     x0, #0

strlen_loop:
    ldrb    w2, [x1]
    cmp     w2, #0
    beq     strlen_done
    add     x0, x0, #1
    add     x1, x1, #1
    b       strlen_loop

strlen_done:
    ldp     x29, x30, [sp], #16
    ret

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

.section __DATA, __data
.p2align 2

prompt:
    .asciz "$$ "
newline:
    .asciz "\n"
token_prefix:
    .asciz "Token ["
token_suffix:
    .asciz "] "
