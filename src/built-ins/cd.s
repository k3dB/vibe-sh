// ARM64v8 Shell for macOS
// Built-in: cd

.extern get_current_path

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl builtin_cd

// Built-in: cd
// x0 = token array
// x1 = token count
// x2 = home value pointer
builtin_cd:
    // Establish frame and save callee-saved registers
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]

    cmp     x1, #1                // check if argument provided
    bgt     cd_path

    // No argument: go to HOME directory
    cbnz    x2, .cd_home          // check if HOME is not null

    // HOME not set: print error
    mov     x0, #2                // stderr
    adrp    x1, cd_home_error@PAGE
    add     x1, x1, cd_home_error@PAGEOFF
    mov     x2, #cd_home_error_len
    mov     x16, #4               // write syscall
    svc     #0x80
    b       cd_done

.cd_home:
    // Save HOME pointer in callee-saved register
    mov     x19, x2

    // Save current directory to oldpwd_buffer before changing
    adrp    x0, oldpwd_buffer@PAGE
    add     x0, x0, oldpwd_buffer@PAGEOFF
    bl      get_current_path

    // Set OLDPWD flag if save succeeded
    cbz     x0, .cd_home_set_flag
    b       .cd_home_skip_flag

.cd_home_set_flag:
    adrp    x0, oldpwd_set@PAGE
    add     x0, x0, oldpwd_set@PAGEOFF
    mov     w1, #1
    str     w1, [x0]

.cd_home_skip_flag:
    mov     x0, x19               // HOME pointer (restored from x19)
    mov     x16, #12              // chdir syscall
    svc     #0x80

    cbz     x0, cd_success
    b       display_cd_error

cd_path:
    // TODO: Handle tilde expansion (~)
    ldr     x20, [x0, #8]         // get the path argument

    // Check if argument is "-" (single character check)
    ldrb    w1, [x20]             // load first byte
    cmp     w1, #'-'              // compare with '-'
    bne     .cd_normal_path       // not dash, proceed with normal path
    ldrb    w1, [x20, #1]         // load second byte
    cbnz    w1, .cd_normal_path   // not just "-", proceed with normal path
    b       cd_dash               // it's "-", handle cd -

.cd_normal_path:
    // Normal path case
    // Save current directory to oldpwd_buffer before changing
    adrp    x19, oldpwd_buffer@PAGE
    add     x19, x19, oldpwd_buffer@PAGEOFF
    mov     x0, x19
    bl      get_current_path

    // Set OLDPWD flag if save succeeded
    cbz     x0, .cd_path_set_flag
    b       .cd_path_skip_flag

.cd_path_set_flag:
    adrp    x0, oldpwd_set@PAGE
    add     x0, x0, oldpwd_set@PAGEOFF
    mov     w1, #1
    str     w1, [x0]

.cd_path_skip_flag:
    mov     x0, x20               // restore path argument
    mov     x16, #12              // chdir syscall
    svc     #0x80

    cbz     x0, cd_success
    b       display_cd_error

cd_dash:
    // Check if OLDPWD has been set
    adrp    x0, oldpwd_set@PAGE
    add     x0, x0, oldpwd_set@PAGEOFF
    ldr     w1, [x0]
    cmp     w1, #1
    bne     cd_dash_error         // OLDPWD not set

    // Save current directory to temp_buffer before switching
    adrp    x0, temp_buffer@PAGE
    add     x0, x0, temp_buffer@PAGEOFF
    bl      get_current_path

    // If get_current_path failed, proceed anyway (non-fatal)
    // Now change to the old directory (stored in oldpwd_buffer)
    adrp    x0, oldpwd_buffer@PAGE
    add     x0, x0, oldpwd_buffer@PAGEOFF
    mov     x16, #12              // chdir syscall
    svc     #0x80

    cbnz    x0, display_cd_error

    // On success, print the new directory (oldpwd_buffer still has the target path)
    // Print oldpwd_buffer to stdout
    adrp    x19, oldpwd_buffer@PAGE
    add     x19, x19, oldpwd_buffer@PAGEOFF
    mov     x20, x19              // x20 = buffer pointer

.cd_dash_strlen_loop:
    ldrb    w21, [x20], #1        // move pointer to end of string
    cbnz    w21, .cd_dash_strlen_loop 

    // Back up from position after null terminator to null terminator
    sub     x20, x20, #1
    // Calculate string length (excluding null terminator)
    sub     x20, x20, x19

    // Print the path
    mov     x0, #1                // stdout
    mov     x1, x19               // buffer pointer
    mov     x2, x20               // length
    mov     x16, #4               // write syscall
    svc     #0x80

    // Print newline
    mov     x0, #1                // stdout
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4               // write syscall
    svc     #0x80

    // Now copy temp_buffer to oldpwd_buffer
    // (so oldpwd_buffer now contains the directory we came from)
    adrp    x0, temp_buffer@PAGE
    add     x0, x0, temp_buffer@PAGEOFF
    adrp    x1, oldpwd_buffer@PAGE
    add     x1, x1, oldpwd_buffer@PAGEOFF
    mov     x2, #1024             // PATH_MAX
    // Simple loop to copy bytes
.cd_dash_copy_loop:
    ldrb    w3, [x0], #1
    strb    w3, [x1], #1
    subs    x2, x2, #1
    bne     .cd_dash_copy_loop

    b       cd_success

cd_dash_error:
    // Print "cd: OLDPWD not set\n" to stderr
    mov     x0, #2                // stderr
    adrp    x1, oldpwd_error@PAGE
    add     x1, x1, oldpwd_error@PAGEOFF
    mov     x2, #oldpwd_error_len
    mov     x16, #4               // write syscall
    svc     #0x80

    mov     x0, #1                // error
    b       cd_done

display_cd_error:
    // Print error message
    mov     x0, #2                // stderr
    adrp    x1, cd_error@PAGE
    add     x1, x1, cd_error@PAGEOFF
    mov     x2, #cd_error_len     // error message length
    mov     x16, #4               // write syscall
    svc     #0x80

    mov     x0, #1                // error
    b       cd_done

cd_success:
    mov     x0, #0                // success

cd_done:
    // Restore registers and return
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

.section __DATA, __bss
.p2align 4
.globl oldpwd_buffer
oldpwd_buffer:
    .zero 1024                    // PATH_MAX buffer for previous directory

.globl oldpwd_set
oldpwd_set:
    .zero 4                       // Flag: 1 if OLDPWD has been set, 0 otherwise

// Temporary buffer for `cd -` to hold current directory before switching
temp_buffer:
    .zero 1024                    // PATH_MAX buffer for temporary storage

.section __TEXT, __cstring

cd_error:
    .asciz "cd: error changing directory\n"
    .set cd_error_len, . - cd_error

cd_home_error:
    .asciz "cd: HOME not set\n"
    .set cd_home_error_len, . - cd_home_error

oldpwd_error:
    .asciz "cd: OLDPWD not set\n"
    .set oldpwd_error_len, . - oldpwd_error

newline:
    .asciz "\n"
