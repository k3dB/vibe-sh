// ARM64v8 Shell for macOS
// Main entry point and REPL loop

.section __TEXT, __text, regular, pure_instructions
.p2align 2

// Buffer for user input
.equ INPUT_BUFFER_SIZE, 256
.equ MAX_TOKENS, 32
.equ MAX_TOKEN_LENGTH, 128

.globl _main

_main:
    stp     x29, x30, [sp, #-16]! // Preserve FP and LR
    stp     x19, x20, [sp, #-16]! // x19 = return code, x20 = path value pointer

    mov     x0, x2                // envp
    bl      find_path
    mov     x20, x0               // Store PATH value pointer

display_prompt:
    mov     x0, #1                // stdout
    adrp    x1, prompt@PAGE
    add     x1, x1, prompt@PAGEOFF
    mov     x2, #3                // length of "$$ "
    mov     x16, #4               // write syscall
    svc     #0x80

    // Read user input
    mov     x0, #0                // stdin
    adrp    x1, input_buffer@PAGE
    add     x1, x1, input_buffer@PAGEOFF
    mov     x2, #INPUT_BUFFER_SIZE
    mov     x16, #3               // read syscall
    svc     #0x80

    mov     x3, x0                // Save the read length
    cbz     x3, exit_shell        // Check for EOF (read returns 0)

    cmp     x3, #-1               // Check for error (read returns -1)
    beq     exit_shell

    // Parse the command
    // x0 = input buffer, x1 = token array, returns x0 = token count
    adrp    x0, input_buffer@PAGE
    add     x0, x0, input_buffer@PAGEOFF
    strb    wzr, [x0, x3]         // Null-terminate the input
    adrp    x1, token_array@PAGE
    add     x1, x1, token_array@PAGEOFF
    bl      parse_command
    mov     x3, x0                // token count

    // Execute the command
    // x0 = token array, x1 = token count, x2 = path buffer
    adrp    x0, token_array@PAGE
    add     x0, x0, token_array@PAGEOFF
    mov     x1, x3
    mov     x2, x20               // PATH value pointer
    bl      execute_command

    mov     x19, x0               // Copy return code for potential exit
    cbnz    x1, exit_shell        // Exit if exit flag is set

    b       display_prompt

exit_shell:
    // Print newline before exit
    mov     x0, #1                // stdout
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1                // length of newline
    mov     x16, #4               // write syscall
    svc     #0x80

    // Exit
    mov     x0, x19               // exit status
    ldp     x19, x20, [sp], #16   // Restore callee-saved registers
    ldp     x29, x30, [sp], #16   // Restore FP and LR

    mov     x16, #1               // exit syscall
    svc     #0x80                 // Exits the process, no code runs after this

.section __TEXT, __cstring

prompt:
    .asciz "$$ "
newline:
    .asciz "\n"
space:
    .asciz " "

.section __DATA, __bss
.p2align 3

// Input buffer for user input
input_buffer:
    .space INPUT_BUFFER_SIZE

// Token array (array of pointers to tokens)
token_array:
    .space MAX_TOKENS * 8
