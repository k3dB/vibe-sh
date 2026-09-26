// ARM64v8 Shell for macOS
// Path utilities module

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl is_absolute_or_relative
.globl get_next_path_component

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
