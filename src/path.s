// ARM64v8 Shell for macOS
// Path utilities module

.extern command_buffer

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl resolve_command_path

// Resolve command path using PATH environment variable
// x0 = command name
// x1 = PATH string pointer
// returns x0 = resolved path pointer (in command_buffer), or NULL if not found
resolve_command_path:
    stp     x29, x30, [sp, #-16]! // Prologue: save FP and LR
    stp     x19, x20, [sp, #-16]! // Save callee-saved registers
    stp     x21, x22, [sp, #-16]!

    mov     x19, x0               // Save command name
    mov     x20, x1               // Save PATH pointer

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

    // Initialize position pointer to NULL for first call
    mov     x21, #0

resolve_path_loop:
    // Get next PATH component
    mov     x0, x20               // PATH pointer
    mov     x1, x21               // Current position
    bl      get_next_path_component

    // x0 = component pointer, x1 = updated position
    cbz     x0, resolve_path_not_found

    // Save component pointer and updated position
    mov     x22, x0               // Component pointer
    mov     x21, x1               // Updated position for next iteration

    // Construct full path in command_buffer: dir + '/' + command
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF

    // Copy directory component to command_buffer
    mov     x1, x22               // Source: directory component
next_component_byte:
    ldrb    w2, [x1], #1
    strb    w2, [x0], #1
    cbnz    w2, next_component_byte

    mov     w2, #'/'              // Append '/' to the path
    strb    w2, [x0], #1

    // Append command name to the path
    mov     x1, x19               // Source: command name

next_command_byte:
    ldrb    w2, [x1], #1
    strb    w2, [x0], #1
    cbnz    w2, next_command_byte

    strb    wzr, [x0]             // Null-terminate the string

    // Return the constructed path
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF
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

    // Return the command_buffer
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF
    b       resolve_path_done

resolve_path_not_found:
    mov     x0, #0                // Return NULL

resolve_path_done:
    ldp     x21, x22, [sp], #16   // Restore callee-saved registers
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16   // Restore FP and LR
    ret

// Get next PATH component
// x0 = PATH string pointer
// x1 = current position pointer (NULL on first call)
// returns x0 = pointer to next component (NULL if no more)
// returns x1 = updated position for next call
get_next_path_component:
    stp     x29, x30, [sp, #-16]! // Prologue: save FP and LR

    // If current position is NULL, start from beginning of PATH
    cbz     x1, get_next_path_start

    // Check if current position points to null terminator (end of PATH)
    ldrb    w2, [x1]
    cbz     w2, no_more_components

    // Current position is valid, continue from there
    b       get_next_path_find_colon

get_next_path_start:
    // Start from beginning of PATH
    mov     x1, x0

    // Check if PATH is empty
    ldrb    w2, [x1]
    cbz     w2, no_more_components

get_next_path_find_colon:
    // Use strchr to find next colon from current position
    mov     x0, x1                // String to search
    mov     w1, #':'              // Character to find
    bl      strchr

    // x0 now contains pointer to colon, or NULL if not found
    cbz     x0, get_next_path_last_component

    // Colon found: return current position as component start
    // and update position to after the colon
    mov     x2, x1                // Save current position (component start)
    add     x1, x0, #1            // Update position to after colon
    mov     x0, x2                // Return component start in x0

    ldp     x29, x30, [sp], #16   // Restore FP and LR
    ret

get_next_path_last_component:
    // No colon found: this is the last component
    // Return current position as component start
    // and set position to NULL (no more components)
    mov     x0, x1                // Return component start in x0
    mov     x1, #0                // Set position to NULL

    ldp     x29, x30, [sp], #16   // Restore FP and LR
    ret

no_more_components:
    mov     x0, #0                // Return NULL
    mov     x1, #0                // Set position to NULL

    ldp     x29, x30, [sp], #16   // Restore FP and LR
    ret
