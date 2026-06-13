// ARM64v8 Shell for macOS
// Main entry point and REPL loop

.section __TEXT, __text, regular, pure_instructions
.p2align 2

// Buffer for user input
.equ INPUT_BUFFER_SIZE, 256
.equ MAX_TOKENS, 32
.equ MAX_TOKEN_LENGTH, 128
.equ PATH_MAX, 1024

.globl _main

_main:
    // Load addresses of buffers each iteration
    adrp    x3, input_buffer@PAGE
    add     x3, x3, input_buffer@PAGEOFF // x3 = pointer to input buffer

    adrp    x4, token_array@PAGE
    add     x4, x4, token_array@PAGEOFF  // x4 = pointer to token array

    adrp    x5, path_buffer@PAGE
    add     x5, x5, path_buffer@PAGEOFF  // x5 = pointer to path buffer

    // Display prompt "$$ "
    mov     x0, #1                       // stdout
    adrp    x1, prompt@PAGE
    add     x1, x1, prompt@PAGEOFF
    mov     x2, #3                       // length of "$$ "
    mov     x16, #4                      // write syscall
    svc     #0x80

    // Read user input
    mov     x0, #0                       // stdin
    mov     x1, x3                       // buffer pointer
    mov     x2, #INPUT_BUFFER_SIZE
    mov     x16, #3                      // read syscall
    svc     #0x80

    // Save the read length
    mov     x6, x0

    // Check for EOF (read returns 0)
    cmp     x6, #0
    beq     exit_shell

    // Check for error (read returns -1)
    cmp     x6, #-1
    beq     exit_shell

    // Null-terminate the input
    strb    wzr, [x3, x6]

    // Parse the command
    // x0 = input buffer, x1 = token array, returns x0 = token count
    mov     x0, x3
    mov     x1, x4
    bl      parse_command
    mov     x6, x0         // x6 = token count

    // Execute the command
    // x0 = token array, x1 = token count, x2 = path buffer
    mov     x0, x4
    mov     x1, x6
    mov     x2, x5
    bl      execute_command

    // Loop back to display prompt
    b       _main

exit_shell:
    // Print newline before exit
    mov     x0, #1
    adrp    x1, newline@PAGE
    add     x1, x1, newline@PAGEOFF
    mov     x2, #1
    mov     x16, #4
    svc     #0x80

    // Exit
    mov     x0, #0         // exit status
    mov     x16, #1        // exit syscall
    svc     #0x80
    ret

.section __DATA, __data
.p2align 2

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

// Path buffer for pwd and cd
path_buffer:
    .space PATH_MAX
