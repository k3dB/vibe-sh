// ARM64v8 Shell for macOS
// Command execution module - built-in command dispatcher

.section __TEXT, __text, regular, pure_instructions
.p2align 2
.globl execute_command

// Constants
.equ PATH_MAX, 1024

// Execute command - check built-ins or execute external command
// x0 = token array
// x1 = token count
// x2 = path buffer
execute_command:
    // x19 = token array
    // x20 = token count
    // x21 = path buffer
    // x22 = command name

    // Prologue
    stp     x29, x30, [sp, #-16]! // Preserve FP and LR
    mov     x29, sp               // Set up new FP
    stp     x19, x20, [sp, #-16]! // Preserve callee-saved registers
    stp     x21, x22, [sp, #-16]!

    mov     x19, x0         // token array
    mov     x20, x1         // token count
    mov     x21, x2         // path buffer

    // Check if token count is 0 (empty line)
    cmp     x20, #0
    beq     execute_done

    // Get first token (command name)
    ldr     x22, [x19]

    // Check for exit built-in
    mov     x0, x22
    bl      strcmp_exit
    cbz     x0, exit

    // Check for echo built-in
    mov     x0, x22
    bl      strcmp_echo
    cbz     x0, echo

    // Check for pwd built-in
    mov     x0, x22
    bl      strcmp_pwd
    cbz     x0, pwd

    // Check for cd built-in
    mov     x0, x22
    bl      strcmp_cd
    cbz     x0, cd

    // Not a built-in, execute external command
    mov     x0, x19
    mov     x1, x20
    bl      execute_external

execute_done:
    mov     x0, xzr         // Return success
    mov     x1, xzr         // Clear exit flag

execute.epilogue:
    ldp     x21, x22, [sp], #16 // Restore callee-saved registers
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16 // Restore FP and LR
    ret

exit:
    mov     x0, xzr         // Return success
    mov     x1, #1          // Set exit flag
    b       execute.epilogue

echo:
    mov     x0, x19
    mov     x1, x20
    bl      builtin_echo
    b       execute_done

pwd:
    bl      builtin_pwd
    b       execute_done

cd:
    mov     x0, x19
    mov     x1, x20
    mov     x2, x21
    bl      builtin_cd
    b       execute_done
