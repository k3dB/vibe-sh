// ARM64v8 Shell for macOS
// String utilities module

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl strcmp
.globl strcmp_exit
.globl strcmp_echo
.globl strcmp_pwd
.globl strcmp_cd
.globl strlen
.globl strchr
.globl strcat

// String comparison functions for built-in commands
// x0 = string to compare
// returns x0 = 0 if match, non-zero if not match
strcmp_exit:
    adrp    x1, str_exit@PAGE
    add     x1, x1, str_exit@PAGEOFF
    b       strcmp

strcmp_echo:
    adrp    x1, str_echo@PAGE
    add     x1, x1, str_echo@PAGEOFF
    b       strcmp

strcmp_pwd:
    adrp    x1, str_pwd@PAGE
    add     x1, x1, str_pwd@PAGEOFF
    b       strcmp

strcmp_cd:
    adrp    x1, str_cd@PAGE
    add     x1, x1, str_cd@PAGEOFF
    b       strcmp

// String comparison
// x0 = string1, x1 = string2
// returns x0 = 0 if equal, non-zero if not equal
strcmp:
strcmp_loop:
    ldrb    w2, [x0], #1
    ldrb    w3, [x1], #1
    cmp     w2, w3
    bne     strcmp_not_equal
    cmp     w2, #0
    beq     strcmp_equal
    b       strcmp_loop

strcmp_not_equal:
    mov     x0, #1
    ret

strcmp_equal:
    mov     x0, #0
    ret

// Calculate string length
// x0 = string pointer
// returns x0 = length
strlen:
    mov     x1, x0
    mov     x0, #0

strlen_loop:
    ldrb    w2, [x1], #1
    cbz     w2, strlen_done
    add     x0, x0, #1
    b       strlen_loop

strlen_done:
    ret

// String concatenation
// x0 = destination, x1 = source
// returns x0 = destination pointer
strcat:
    mov     x2, x0                // Save original destination pointer

    // Find end of destination string
strcat_find_end:
    ldrb    w3, [x0], #1
    cbnz    w3, strcat_find_end

    // x0 now points to null terminator, back up one
    sub     x0, x0, #1

    // Copy source to destination
strcat_copy_loop:
    ldrb    w3, [x1], #1
    strb    w3, [x0], #1
    cbnz    w3, strcat_copy_loop

    // Return original destination pointer
    mov     x0, x2
    ret

// Find character in string
// x0 = string pointer, x1 = character to find
// returns x0 = pointer to character, or NULL if not found
strchr:
    mov     x2, x0
strchr_loop:
    ldrb    w3, [x2], #1
    cmp     w3, w1
    beq     strchr_found
    cbz     w3, strchr_not_found
    b       strchr_loop

strchr_found:
    sub     x0, x2, #1
    ret

strchr_not_found:
    mov     x0, #0
    ret

.section __TEXT, __cstring

str_exit:
    .asciz "exit"
str_echo:
    .asciz "echo"
str_pwd:
    .asciz "pwd"
str_cd:
    .asciz "cd"
