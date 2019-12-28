%include    'stdfunc.asm'
%include    'network.asm'

SECTION .data
usage1      db 'Usage: ', 0x0           ; Usage message beginning
usage2      db ' [DOMAIN] [PORT]', 0x0  ; Usage message ending

domainPrint db 'Domain: ', 0x0          ; Domain print label
portPrint   db 'Port: ', 0x0            ; Port print label

SECTION .bss
domain  resb 255,                      ; Domain after ntohs
port    resb 8                      ; Port number

SECTION .text
global _start

_start:
    pop     ecx             ; first value on the stack is the number of arguments
    pop     edx             ; second value on the stack is the program name (discarded when we initialise)
    sub     ecx, 1          ; decrease ecx by 1 (number of arguments without program name
    cmp     ecx, 0x02       ; check if the number of arguments is 2 
    je      continue        ; else continue rest of program

incorrectUsage:
    mov     eax, usage1     ; move the beginning of usage statement into EAX
    call    sprint          ; print the beginning of the usage statment

    mov     eax, edx        ; move the program name in edx to eax
    call    sprint          ; print the program name
    
    mov     eax, usage2     ; move the end of the usage statment into EAX
    call    sprintLF        ; print the final usage statement with linefeed

    call    quit            ; quit

continue:
    ; Load and print the values
    pop     ebx                 ; pop the first argument (the domain)
    mov     [domain], ebx       ; move the value in ebx into the domain .bss

    mov     eax, domainPrint    ; move the domainPrint string into eax to print
    call    sprint

    mov     eax, [domain]       ; move the input variable address into eax
    call    sprintLF            ; print the domain variable with line feed

    mov     eax, domainPrint
    call    sprint

    pop     ebx                 ; pop the second argument (the port)
    mov     [port], ebx         ; move the value in ebx into the port .bss

    mov     eax, portPrint      ; move the portPrint string into eax to print
    call    sprint

    mov     eax, [port]         ; move the port variable address into eax
    call    sprintLF            ; print the port variable with the line feed

    mov     eax, [domain]       ; move the domain into eax
    mov     ebx, [port]         ; move the port into ebx
    call    printReq            ; print the request

    call    quit
    