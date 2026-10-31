// ARM64v8 Shell for macOS
// Built-in: cd

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl builtin_cd

// Built-in: cd
// x0 = token array
// x1 = token count
// x2 = home value pointer
builtin_cd:
    cmp     x1, #1                // check if argument provided
    bgt     cd_path

    // No argument: go to HOME directory
    cbnz    x2, .cd_home          // check if HOME is not null

    // HOME not set: print error
    mov     x0, #1                // stdout
    adrp    x1, cd_home_error@PAGE
    add     x1, x1, cd_home_error@PAGEOFF
    mov     x2, #19               // error message length
    mov     x16, #4               // write syscall
    svc     #0x80
    b       cd_done

.cd_home:
    mov     x0, x2                // HOME pointer
    mov     x16, #12              // chdir syscall
    svc     #0x80

    cmp     x0, #0                // check for error
    beq     cd_success
    b       display_cd_error

cd_path:
    // TODO: Handle tilde expansion (~)
    ldr     x0, [x0, #8]          // get the path argument

    mov     x16, #12              // chdir syscall
    svc     #0x80

    cmp     x0, #0                // check for error
    beq     cd_success

display_cd_error:
    // Print error message
    mov     x0, #1                // stdout
    adrp    x1, cd_error@PAGE
    add     x1, x1, cd_error@PAGEOFF
    mov     x2, #29               // error message length
    mov     x16, #4               // write syscall
    svc     #0x80

    mov     x0, #1                // error
    b       cd_done

cd_success:
    mov     x0, #0                // success

cd_done:
    ret

.section __TEXT, __cstring

cd_error:
    .asciz "cd: error changing directory\n"

cd_home_error:
    .asciz "cd: HOME not set\n"
