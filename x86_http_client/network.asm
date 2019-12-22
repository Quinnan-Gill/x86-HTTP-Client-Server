%ifndef _NETWORK_H_
%define _NETWORK_H_

%include    'stdfunc.asm'

SECTION .data
; our request strings
request1 db 'GET / HTTP/1.1', 0x0d, 0x0a, 'Host: '
request2 db ':', 0x0
request3 db 0x0d, 0x0a, 0x0d, 0x0a, 0x0

SECTION .bss
octal   resb 4      ; the octal strings for each division of the ip address
request resb 255,   ; the memory segment with the completed address

SECTION .text
;------------------------------------------
; uint32_t reverse(uint_32 reg)
; Takes a regesiter (eax) and reverses the order of the bytes for endianess
reverse:
    push    ecx
    push    ebx

    xor     ecx, ecx    ; clear 
    
.reverseLoop:
    test    eax, eax
    je      .finished

    mov     ebx, eax

    shl     ecx, 8
    and     ebx, 0xFF
    or      ecx, ebx
    
    shr     eax, 8

    jmp .reverseLoop

.finished:
    mov     eax, ecx

    pop     ebx
    pop     ecx
    ret


;------------------------------------------
; uint32_t ntohs(String ip)
; Takes a IPv4 address string and converts it into it's hex equivalent
ntohs:
    push    edx
    push    ecx
    push    ebx
    push    esi
    push    edi

    mov     esi, eax        ; move the ip string in eax to edx
    mov     ecx, 0          ; ecx is the counter
    mov     edx, 0          ; zero out edx lower and upper bytes of edx
    xor     edi, edi        ; zero out edx lower and upper bytes of eax

    ; push    dword 0x00000000 ; put zero onto the stack
    
.decodeIP:
    xor     ebx, ebx        ; resets both lower and upper bytes of ebx to be 0
    mov     bl, [esi+ecx]   ; move a single byte into ebx register's lower half
    cmp     bl, 0x0         ; compare ebx register's lower half value against ascii value 0 (null byte)
    je      .finished       ; if null byte is encountered then finish execution
    cmp     bl, 0x2e        ; compare ebx register's lower half value against ascii value 46 (character value '.')
    je      .decodeOctal

    mov     [octal+edx], bl ; move the byte into the octal 
    inc     ecx             ; increment ecx (our counter register)
    inc     edx             ; increment edx (our octal counter register)
    jmp     .decodeIP

.decodeOctal:
    mov     ebx, 0x0
    mov     [octal+edx], bl ; add null byte to end

    mov     eax, octal
    call    atoi            ; puts the integer converted into eax

    shl     edi, 8          ; shift left the store register by 8
    and     eax, 0xff       ; mask the eax register
    or      edi, eax        ; logically add (or operation) to the result
    
    inc     ecx             ; increment ecx to get past '.'
    mov     edx, 0          ; reset octal count
    jmp     .decodeIP

.finished:
    mov     [octal+edx], bl ; add null byte to end

    mov     eax, octal
    call    atoi            ; puts the integer converted into eax

    shl     edi, 8          ; shift left the store register by 8
    and     eax, 0xff       ; mask the eax register
    or      edi, eax

    mov     eax, edi        ; move result in edi to eax 

    call    reverse         ; reverse endianess
    
    pop     edi             ; reset registers
    pop     esi
    pop     ebx
    pop     ecx
    pop     edx
    ret

;------------------------------------------
; socket_t socket()
; Create a socket and returns the socket file descriptor -1 if error
socket:
    push    ecx         ; save registers on the stack
    push    ebx

    push    byte 6      ; push 6 onto the stack (IPPROTO_TCP)
    push    byte 1      ; push 1 onto the stack (SOCK_STREAM)
    push    byte 2      ; push 2 onto the stack (PF_INET)
    mov     ecx, esp    ; move address of arguments into ecx
    mov     ebx, 1      ; invoke subroutine SOCKET (1)
    mov     eax, 102    ; invoke SYS_SOCKETCALL (kernel opcode 102)
    int     0x80        ; call the kernel 

    pop     esi
    pop     ebx
    pop     ecx
    ret

;------------------------------------------
; int connect(socket_t fd, String domain, String port)
; connect using the file descriptor and the converted domain and port
connect:
    push    edi
    push    esi
    push    edx

    mov     edi, eax            ; move return value of SYS_SOCKETCALL into edi (file descriptor for new socket, or -1 on error)
    
    mov     eax, ebx            ; move the domain string in ebx into the eax register
    call    ntohs               ; convert the domain string into a workable value
    push    dword eax           ; push domain onto the stack using ebx for IP ADDRESS (reverse byte order)

    mov     eax, ecx            ; move the port string in ecx into the eax register
    push    word ax             ; push the 16 part of eax (ax) onto stack for the PORT (reverse byte order)

    push    word 2              ; push 2 dec onto stack AF_INET
    mov     ecx, esp            ; move address of stack pointer into ecx
    push    byte 16             ; push 16 dec onto stack (arguments length)
    push    ecx                 ; push the address of arguments onto stack
    push    edi                 ; push the file descriptor onto stack
    mov     ecx, esp            ; move the address of arguments into ecx
    mov     ebx, 3              ; invoke subroutine CONNECT (3)
    mov     eax, 102            ; invoke SYS_SOCKETCALL (kerenl opcode 102)
    int     0x80                ; call the kernel

    pop    edi
    pop    esi
    pop    edx
    ret

;------------------------------------------
; void createReq(String domain, String port)
; Takes the domain and port and loads it into the resquest memory address
createReq:
    push    edx
    push    ecx
    push    edi

    mov     edi, eax            ; move the value in eax to edi
    
    mov     eax, request1       ; move the first part of the request to eax
    call    slen                ; get length of request1
    
    mov     ecx, eax            ; save the length in ecx
    mov     eax, request1       ; move the first part of the request again
    mov     [request1], 

    pop     edi
    pop     ecx
    pop     edx
    ret


;------------------------------------------
; int writeReq(socket_t fd, String domain, String port)
; write the request to the socket and returns -1 if failure
writeReq:
    push    edx 
    push    edi
    
    mov     edi, eax            ; store the value in eax (the socket pointer) in edi
    
    mov     eax, request1       ; move the first part of the request into the 

    mov     edx, 43             ; move 43 dec into edx (length in bytes to write)
    mov     ecx, request        ; 

    pop     edi
    pop     edx 
    ret

%endif