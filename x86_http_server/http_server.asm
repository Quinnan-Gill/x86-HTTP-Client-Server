%include    'stdfunc.asm'
%include    'network.asm'

SECTION .data
prompt  db  'x86 HTTP Server TODO', 0x0

SECTION .text
global _start

_start:
    mov     eax, prompt
    call    sprintLF

    call    quit
    
    