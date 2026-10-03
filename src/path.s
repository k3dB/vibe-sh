// ARM64v8 Shell for macOS
// Path utilities module

.extern command_buffer

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl resolve_command_path

// Resolve command path using PATH environment variable
// x0 = command name
// x1 = PATH string pointer
// x2 = current position pointer (NULL on first call)
// returns x0 = resolved path pointer (in command_buffer), or NULL if not found
// returns x1 = updated position for next call
resolve_command_path:
    stp     x29, x30, [sp, #-16]! // Prologue: save FP and LR
    stp     x19, x20, [sp, #-16]! // Save callee-saved registers
    stp     x21, x22, [sp, #-16]!

    mov     x19, x0               // Save command name
    mov     x20, x1               // Save PATH pointer
    mov     x21, x2               // Save current position

    // Check if command name contains '/' (already a path)
    // x0 already has string pointer (command name)
    mov     w1, #'/'              // x1 = character to find ('/')
    bl      strchr                // Call strchr to find '/' in string

    // strchr returns pointer to '/' if found, or NULL (0) if not found
    cbnz    x0, resolve_path_as_is

    // Check if PATH is NULL or empty
    cbz     x20, resolve_path_not_found
    ldrb    w2, [x20]
    cbz     w2, resolve_path_not_found

    // Get next PATH component
    cmp     x21, #0
    csel    x0, x21, x20, ne

    // Check if current position points to null terminator (end of PATH)
    ldrb    w2, [x0]
    cbz     w2, resolve_path_not_found

    cmp     w2, #':'              // If in between components,
    cinc    x0, x0, eq            // move to first byte of next component

    // Check for more components in case PATH ends with a colon
    cbz     w2, resolve_path_not_found

    mov     x21, x0               // Path component pointer

    // Construct full path in command_buffer: dir + '/' + command
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF

    // Copy directory component to command_buffer
next_component_byte:
    ldrb    w2, [x21], #1
    cmp     w2, #':'
    beq     .append_slash
    strb    w2, [x0], #1
    b       next_component_byte

.append_slash:
    mov     w2, #'/'              // Append '/' to the path
    strb    w2, [x0], #1

    // Append command name to the path
    mov     x1, x19               // Source: command name

next_command_byte:
    ldrb    w2, [x1], #1
    strb    w2, [x0], #1
    cbnz    w2, next_command_byte

    strb    wzr, [x0]             // Null-terminate the command buffer

    // Return the constructed path and updated position
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF
    mov     x1, x21               // Return updated position
    b       resolve_path_done

resolve_path_as_is:
    // Command already contains '/', return it as-is
    // Copy command name to command_buffer
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF

    mov     x1, x19               // Source: command name

next_command_as_is_byte:
    ldrb    w2, [x1], #1
    strb    w2, [x0], #1
    cbnz    w2, next_command_as_is_byte

    strb    wzr, [x0]             // Null-terminate the string

    // Return the command_buffer and position set to NULL (no more paths to try)
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF
    mov     x1, #0                // Set position to NULL (command is absolute path)
    b       resolve_path_done

resolve_path_not_found:
    mov     x0, #0                // Return NULL
    mov     x1, #0                // Set position to NULL

resolve_path_done:
    ldp     x21, x22, [sp], #16   // Restore callee-saved registers
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16   // Restore FP and LR
    ret
