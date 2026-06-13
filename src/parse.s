// ARM64v8 Shell for macOS
// Command parsing module

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.global parse_command

// Parse command into tokens (basic space-delimited version)
// x0 = input buffer (null-terminated)
// x1 = token array (array of pointers)
// returns x0 = number of tokens
parse_command:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp

    // Save callee-saved registers we'll use
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    mov     x19, x0         // x19 = input buffer (read pointer)
    mov     x20, x1         // x20 = token array
    mov     x21, #0         // x21 = token count
    mov     x22, #0         // x22 = in_token flag (0 = not in token, 1 = in token)

parse_loop:
    ldrb    w3, [x19]       // Load character (don't advance yet)
    cmp     w3, #0
    beq     parse_done      // End of string

    // Check for space
    cmp     w3, #32
    beq     parse_space

    // Regular character
    cmp     x22, #0
    bne     parse_in_token  // Already in token

    // Start of new token
    str     x19, [x20, x21, lsl #3]  // Store pointer to current position
    add     x21, x21, #1              // Increment token count
    mov     x22, #1                   // Set in_token flag
    add     x19, x19, #1              // Advance read pointer
    b       parse_loop

parse_in_token:
    add     x19, x19, #1              // Advance read pointer
    b       parse_loop

parse_space:
    add     x19, x19, #1              // Advance read pointer
    cmp     x22, #0
    beq     parse_loop     // Not in token, just skip

    // End of token - null-terminate it
    strb    wzr, [x19, #-1]  // Null-terminate at previous position
    mov     x22, #0          // Clear in_token flag
    b       parse_loop

parse_done:
    // Check if we were in a token at the end
    cmp     x22, #0
    beq     parse_return

    // Null-terminate the last token
    strb    wzr, [x19, #-1]

parse_return:
    mov     x0, x21         // Return token count

    // Restore callee-saved registers
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
