// ARM64v8 Shell for macOS
// Command parsing module

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl parse_command

// Parse command into tokens (basic space-delimited version)
// x0 = input buffer (null-terminated)
// x1 = token array (array of pointers)
// returns x0 = number of tokens
parse_command:
    // x2 = input buffer (read pointer)
    // x3 = token array
    // x4 = token count
    // x5 = in_token flag (0 = not in token, 1 = in token)
    // x6 = current character

    mov     x2, x0         // x2 = input buffer (read pointer)
    mov     x3, x1         // x3 = token array
    mov     x4, #0         // x4 = token count
    mov     x5, #0         // x5 = in_token flag

parse_loop:
    ldrb    w6, [x2]       // Load character (don't advance yet)
    cmp     w6, #0
    beq     parse_done     // End of string

    // Check for space or newline
    cmp     w6, #32
    beq     parse_space
    cmp     w6, #10
    beq     parse_space

    // Regular character
    cmp     x5, #0
    bne     parse_in_token  // Already in token

    // Start of new token
    str     x2, [x3, x4, lsl #3]  // Store pointer to current position
    add     x4, x4, #1            // Increment token count
    mov     x5, #1                // Set in_token flag
    add     x2, x2, #1            // Advance read pointer
    b       parse_loop

parse_in_token:
    add     x2, x2, #1     // Advance read pointer
    b       parse_loop

parse_space:
    add     x2, x2, #1     // Advance read pointer
    cmp     x5, #0
    beq     parse_loop     // Not in token, just skip

    // End of token - null-terminate it
    strb    wzr, [x2, #-1] // Null-terminate at previous position
    mov     x5, #0         // Clear in_token flag
    b       parse_loop

parse_done:
    // Check if we were in a token at the end
    cmp     x5, #0
    beq     parse_return

    // Null-terminate the last token
    strb    wzr, [x2, #-1]

parse_return:
    mov     x0, x4         // Return token count
    ret
