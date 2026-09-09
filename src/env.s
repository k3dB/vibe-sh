// ARM64v8 Shell for macOS
// Environment variable handling module

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl find_path

// Get parent process environment and extract PATH
// Returns pointer to PATH string in x0, or NULL if not found
find_path:
    mov     x2, #0                // envp index

next_env:
    ldr     x1, [x0, x2]          // load envp[i]
    cbz     x1, not_found         // if NULL, PATH not found
    add     x2, x2, #8            // next envp index

    ldrb    w3, [x1]              // load first byte of envp[i]
    cmp     w3, #'P'              // check if first byte is 'P'
    bne     next_env              // if not, continue to next envp

    ldrb    w3, [x1, #1]          // load second byte of envp[i]
    cmp     w3, #'A'              // check if second byte is 'A'
    bne     next_env              // if not, continue to next envp

    ldrb    w3, [x1, #2]          // load third byte of envp[i]
    cmp     w3, #'T'              // check if third byte is 'T'
    bne     next_env              // if not, continue to next envp

    ldrb    w3, [x1, #3]          // load fourth byte of envp[i]
    cmp     w3, #'H'              // check if fourth byte is 'H'
    bne     next_env              // if not, continue to next envp

    ldrb    w3, [x1, #4]          // load fifth byte of envp[i]
    cmp     w3, #'='              // check if fifth byte is '='
    bne     next_env              // if not, continue to next envp

    // PATH found, return pointer to PATH value (after '=')
    add     x0, x1, #5            // skip "PATH=" prefix
    b       find_path_done

not_found:
    mov     x0, #0                // return NULL

find_path_done:
    ret
