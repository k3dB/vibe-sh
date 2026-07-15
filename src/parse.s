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
    mov     x3, #0               // token count
    mov     x4, #0               // in_token flag

parse_loop:
    ldrb    w5, [x0]             // Load character (do not advance yet)
    cbz     w5, parse_done       // End of input?

    // Check for space or newline
    cmp     w5, #' '
    beq     parse_space
    cmp     w5, #'\n'
    beq     parse_space

    cbnz    x4, parse_in_token   // Already in token?

    // Start of new token
    str     x0, [x1, x3, lsl #3] // Store pointer to current position
    add     x3, x3, #1           // Increment token count
    mov     x4, #1               // Set in_token flag
    add     x0, x0, #1           // Advance read pointer
    b       parse_loop

parse_in_token:
    add     x0, x0, #1           // Advance read pointer
    b       parse_loop

parse_space:
    add     x0, x0, #1           // Advance read pointer
    cbz     x4, parse_loop       // Not in token?

    // End of token - null-terminate it
    strb    wzr, [x0, #-1]       // Null-terminate at previous position
    mov     x4, #0               // Clear in_token flag
    b       parse_loop

parse_done:
    cbz     x4, parse_return     // Check if we were in a token at the end
    strb    wzr, [x0, #-1]       // Null-terminate the last token

parse_return:
    mov     x0, x3               // Return token count
    ret
