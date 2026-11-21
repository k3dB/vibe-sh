// ARM64v8 Shell for macOS
// Tilde expansion module
//
// Expands a leading '~' (only when followed by '/' or end-of-word) to the
// HOME directory value. '~user' forms and mid-word '~' are left literal.
//
// Buffer model: expanded tokens are appended to tilde_buffer because tokens
// live in-place in input_buffer and cannot grow. expand_tokens resets the
// cursor on each call; the shell is single-threaded and the buffer is only
// read before the next command (or inherited by the forked child).

.equ TILDE_BUFFER_SIZE, 8192

.extern strlen

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl expand_tokens

// Expand '~' in every token, in place in the token array.
// x0 = token array (array of char* pointers)
// x1 = token count
// x2 = HOME value pointer (may be NULL)
//
// Calling convention notes:
// - x0-x17 and x30 are clobbered by bl expand_tilde.
// - token array, count, index, cursor, and HOME are kept in x19-x24.
// - Returns nothing meaningful; callers reuse x19-x22 afterwards.
expand_tokens:
    // x19 = token array
    // x20 = token count
    // x21 = home pointer
    // x22 = loop index
    // x23 = destination cursor in tilde_buffer
    // x24 = tilde_buffer end

    // Prologue
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    stp     x23, x24, [sp, #-16]!

    mov     x19, x0               // token array
    mov     x20, x1               // token count
    mov     x21, x2               // home pointer
    mov     x22, #0               // loop index

    // Initialize cursor to tilde_buffer base, end to base + size
    adrp    x9, tilde_buffer@PAGE
    add     x9, x9, tilde_buffer@PAGEOFF
    mov     x23, x9               // cursor = base
    add     x24, x9, #TILDE_BUFFER_SIZE  // end = base + size

expand_tokens_loop:
    cmp     x22, x20
    bge     expand_tokens_done

    // Load token pointer
    ldr     x0, [x19, x22, lsl #3]

    mov     x1, x21               // HOME pointer
    mov     x2, x23               // destination cursor
    mov     x3, x24               // buffer end
    bl      expand_tilde

    // Store result pointer (expanded dest or original token) back
    str     x0, [x19, x22, lsl #3]

    // Advance cursor only when expansion wrote bytes
    cbz     x1, expand_tokens_next
    add     x23, x23, x1

expand_tokens_next:
    add     x22, x22, #1
    b       expand_tokens_loop

expand_tokens_done:
    mov     x0, xzr

    // Epilogue
    ldp     x23, x24, [sp], #16
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// Expand a single token's leading '~' into the destination buffer.
// x0 = token pointer
// x1 = HOME value pointer (may be NULL)
// x2 = destination cursor in tilde_buffer
// x3 = tilde_buffer end pointer
//
// Return contract:
//   Expanded:        x0 = dest pointer, x1 = bytes written incl. NUL
//   Not expanded:    x0 = original token pointer, x1 = 0
//     (token doesn't start with '~', second char isn't '/' or NUL,
//      HOME is NULL, or insufficient buffer space)
//
// Persistent values live in x19-x23; all are preserved.
expand_tilde:
    // x19 = token pointer
    // x20 = home pointer
    // x21 = destination cursor
    // x22 = buffer end
    // x23 = required byte count

    // Prologue
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    stp     x23, x24, [sp, #-16]!

    mov     x19, x0               // token pointer
    mov     x20, x1               // home pointer
    mov     x21, x2               // destination cursor
    mov     x22, x3               // buffer end

    // Token must start with '~'
    ldrb    w4, [x19]
    cmp     w4, #'~'
    bne     tilde_not_expanded

    // HOME must be set
    cbz     x20, tilde_not_expanded

    // '~' must be followed by '/' or end-of-word (no '~user' support)
    ldrb    w4, [x19, #1]
    cmp     w4, #'/'
    beq     tilde_eligible
    cbz     w4, tilde_eligible
    b       tilde_not_expanded

tilde_eligible:
    // required = strlen(HOME) + strlen(token)
    // (result is HOME + token[1:] + NUL = home_len + tok_len bytes)
    mov     x0, x20
    bl      strlen
    mov     x23, x0               // home length

    mov     x0, x19
    bl      strlen
    add     x23, x23, x0          // required = home_len + tok_len

    // Capacity check: cursor + required <= end
    add     x4, x21, x23
    cmp     x4, x22
    bhi     tilde_not_expanded

    // Copy HOME string (without NUL) to destination
    mov     x0, x20               // src = HOME
    mov     x1, x21               // dst = cursor

tilde_copy_home:
    ldrb    w4, [x0], #1
    cbz     w4, tilde_copy_rest
    strb    w4, [x1], #1
    b       tilde_copy_home

tilde_copy_rest:
    // Copy token[1:] including its NUL terminator
    add     x0, x19, #1           // src = token + 1 (skip '~')

tilde_copy_rest_loop:
    ldrb    w4, [x0], #1
    strb    w4, [x1], #1
    cbnz    w4, tilde_copy_rest_loop

    // Return dest pointer and bytes written
    mov     x0, x21
    mov     x1, x23
    b       tilde_done

tilde_not_expanded:
    mov     x0, x19               // original token pointer
    mov     x1, xzr               // 0 bytes written

tilde_done:
    // Epilogue
    ldp     x23, x24, [sp], #16
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

.section __DATA, __bss
.p2align 4

// Buffer holding expanded tokens for the current command
tilde_buffer:
    .space TILDE_BUFFER_SIZE
