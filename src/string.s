// ARM64v8 Shell for macOS
// String utilities module

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.global strcmp
.global strcmp_exit
.global strcmp_echo
.global strcmp_pwd
.global strcmp_cd
.global strlen

// String comparison functions for built-in commands
// x0 = string to compare
// returns x0 = 0 if match, non-zero if not match
strcmp_exit:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x1, str_exit@PAGE
    add     x1, x1, str_exit@PAGEOFF
    bl      strcmp
    ldp     x29, x30, [sp], #16
    ret

strcmp_echo:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x1, str_echo@PAGE
    add     x1, x1, str_echo@PAGEOFF
    bl      strcmp
    ldp     x29, x30, [sp], #16
    ret

strcmp_pwd:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x1, str_pwd@PAGE
    add     x1, x1, str_pwd@PAGEOFF
    bl      strcmp
    ldp     x29, x30, [sp], #16
    ret

strcmp_cd:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x1, str_cd@PAGE
    add     x1, x1, str_cd@PAGEOFF
    bl      strcmp
    ldp     x29, x30, [sp], #16
    ret

// String comparison
// x0 = string1, x1 = string2
// returns x0 = 0 if equal, non-zero if not equal
strcmp:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

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
    ldp     x29, x30, [sp], #16
    ret

strcmp_equal:
    mov     x0, #0
    ldp     x29, x30, [sp], #16
    ret

// Calculate string length
// x0 = string pointer
// returns x0 = length
strlen:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     x1, x0
    mov     x0, #0

strlen_loop:
    ldrb    w2, [x1]
    cmp     w2, #0
    beq     strlen_done
    add     x0, x0, #1
    add     x1, x1, #1
    b       strlen_loop

strlen_done:
    ldp     x29, x30, [sp], #16
    ret

.section __DATA, __data
.p2align 2

str_exit:
    .asciz "exit"
str_echo:
    .asciz "echo"
str_pwd:
    .asciz "pwd"
str_cd:
    .asciz "cd"
