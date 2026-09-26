// ARM64v8 Shell for macOS
// Path utilities module

.extern command_buffer

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl is_absolute_or_relative
.globl get_next_path_component
.globl resolve_command_path

// Check if command name is an absolute or relative path
// x0 = command name
// returns x0 = 1 if contains '/', 0 if not
is_absolute_or_relative:
    mov     x1, x0                // Save command name in x1 for strchr
    mov     w0, #'/'              // Load '/' character to find
    bl      strchr                // Call strchr to find '/' in string

    // strchr returns pointer to '/' if found, or NULL (0) if not found
    cbnz    x0, is_absolute_or_relative_found
    mov     x0, #0                // Not found, return 0
    ret

is_absolute_or_relative_found:
    mov     x0, #1                // Found, return 1
    ret

// Get next PATH component
// x0 = PATH string pointer
// x1 = current position pointer (NULL on first call)
// returns x0 = pointer to next component (NULL if no more)
// returns x1 = updated position for next call
get_next_path_component:
    // If current position is NULL, start from beginning of PATH
    cbz     x1, get_next_path_start

    // Check if current position points to null terminator (end of PATH)
    ldrb    w2, [x1]
    cbz     w2, get_next_path_done

    // Current position is valid, continue from there
    b       get_next_path_find_colon

get_next_path_start:
    // Start from beginning of PATH
    mov     x1, x0

    // Check if PATH is empty
    ldrb    w2, [x1]
    cbz     w2, get_next_path_done

get_next_path_find_colon:
    // Use strchr to find next colon from current position
    mov     x0, x1                // String to search
    mov     w0, #':'              // Character to find
    bl      strchr

    // x0 now contains pointer to colon, or NULL if not found
    cbz     x0, get_next_path_last_component

    // Colon found: return current position as component start
    // and update position to after the colon
    mov     x2, x1                // Save current position (component start)
    add     x1, x0, #1            // Update position to after colon
    mov     x0, x2                // Return component start in x0
    ret

get_next_path_last_component:
    // No colon found: this is the last component
    // Return current position as component start
    // and set position to NULL (no more components)
    mov     x0, x1                // Return component start in x0
    mov     x1, #0                // Set position to NULL
    ret

get_next_path_done:
    // No more components
    mov     x0, #0                // Return NULL
    mov     x1, #0                // Set position to NULL
    ret

// Resolve command path using PATH environment variable
// x0 = command name
// x1 = PATH string pointer
// returns x0 = resolved path pointer (in command_buffer), or NULL if not found
resolve_command_path:
    stp     x19, x20, [sp, #-16]! // Save callee-saved registers
    stp     x21, x22, [sp, #-16]!

    mov     x19, x0               // Save command name
    mov     x20, x1               // Save PATH pointer

    // Check if command name contains '/' (already a path)
    mov     x0, x19
    bl      is_absolute_or_relative
    cbnz    x0, resolve_path_is_path

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

    // Clear command_buffer (set first byte to 0 to make it an empty string)
    strb    wzr, [x0]

    // Copy directory component to command_buffer
    mov     x1, x22               // Source: directory component
    bl      strcat

    // Append '/' to the path
    adrp    x1, slash@PAGE
    add     x1, x1, slash@PAGEOFF
    bl      strcat

    // Append command name to the path
    mov     x1, x19               // Source: command name
    bl      strcat

    // Return the constructed path
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF
    b       resolve_path_done

resolve_path_is_path:
    // Command already contains '/', return it as-is
    // Copy command name to command_buffer
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF

    // Clear command_buffer (set first byte to 0 to make it an empty string)
    strb    wzr, [x0]

    mov     x1, x19               // Source: command name
    bl      strcat

    // Return the command_buffer
    adrp    x0, command_buffer@PAGE
    add     x0, x0, command_buffer@PAGEOFF
    b       resolve_path_done

resolve_path_not_found:
    mov     x0, #0                // Return NULL

resolve_path_done:
    ldp     x21, x22, [sp], #16   // Restore callee-saved registers
    ldp     x19, x20, [sp], #16
    ret

.section __TEXT, __cstring

slash:
    .asciz "/"
