%ifndef _NETWORK_H_
%define _NETWORK_H_

%include    'stdfunc.asm'

SECTION .data
; our request strings
request1 db 'GET / HTTP/1.1', 0x0d, 0x0a, 'Host: ', 0x0
request2 db ':', 0x0
request3 db 0x0d, 0x0a, 0x0d, 0x0a, 0x0

SECTION .bss
octal   resb 4      ; the octal strings for each division of the ip address
request resb 255,   ; the memory segment with the completed address
buffer  resb 2,     ; variable store response

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

    pop     ebx         ; remove all the pushed bytes
    pop     ebx
    pop     ebx 

    pop     ebx         ; reset registers
    pop     ecx
    ret

;------------------------------------------
; int portFlip(int port)
; Flips the bytes of the port value
portFlip:
    push    ebx

    mov     ebx, eax    ; mov eax (the port) into ebx
    and     ebx, 0xff   ; mask the lower byte of ebx
    shl     ebx, 8      ; shift ebx by a byte to the left

    shr     eax, 8      ; shift eax by a byte to the right
    and     eax, 0xff   ; mask the lower byte of eax
    or      eax, ebx    ; or the upper ebx to lower eax
    
    pop     ebx
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
    call    atoi                ; convert the eax
    call    portFlip            ; ntohs the port value
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

    pop     edi                 ; edi was pushed now lets pop
    pop     ecx                 ; ecx was pushed now lets pop
    pop     byte edx            ; pop the byte 16 into edx register's lower half
    pop     edx                 ; pop the words for 2 and port into edx
    pop     edx                 ; pop the domain into edx

    pop    edx
    pop    esi
    pop    edi
    ret

;------------------------------------------
; int moveToMem(String phrase, int offset)
; Takes a string and loads it into the request bss section
moveToMem:
    push    edx                     ; save registers
    push    ecx
    push    esi

    mov     esi, eax                ; move the phrase string from eax into esi
    mov     ecx, 0                  ; move zero into esi (the string counter)

.memCopyLoop:
    xor     edx, edx                ; resets both lower and upper bytes of 
    mov     dl, [esi+ecx]           ; move a single byte into edx register's lower half
    cmp     dl, 0x0                 ; compare edx register's lower half value against ascii value 0 (null byte)
    je     .finished               ; if null byte is encountered then finish execution
    mov     [request+ebx+ecx], dl   ; move the character byte in edx register's lower half into 
                                    ; the request memory address + the ebx offset + character position
    inc     ecx                     ; increment ecx by 1
    jmp     .memCopyLoop            ; loop back up

.finished:
    mov     eax, ebx                ; move the ebx offset into eax
    add     eax, ecx                ; add the number of characters passed to the offset
                                    ; this returns the new offset
    pop     esi                     ; reset registers
    pop     ecx
    pop     edx
    ret

;------------------------------------------
; int createReq(String domain, String port)
; Takes the domain and port and loads it into the resquest memory address
createReq:
    push    edx
    push    ecx

    mov     ecx, eax            ; move eax (domain string) into ecx for later
    mov     edx, ebx            ; move edx (port string) into edx for later
    
    mov     eax, request1       ; move the first part of the request into the eax register
    mov     ebx, 0              ; move the offset 0 into the ebx register
    call    moveToMem           ; call moveToMem putting request1 into request bss

    mov     ebx, eax            ; move the new offset (in return address eax) into ebx
    mov     eax, ecx            ; move the domain (in ecx) into eax
    call    moveToMem           ; call moveToMem appending the domain to the request bss

    mov     ebx, eax            ; move the new offset (in return address eax) into ebx
    mov     eax, request2       ; move the second part of the request into the eax register
    call    moveToMem           ; call moveToMem appending request2 onto the request bss

    mov     ebx, eax            ; mov the new offset (in return address eax) into ebx
    mov     eax, edx            ; move the port (in edx) into eax
    call    moveToMem           ; call moveToMem appending the port to the request bss

    mov     ebx, eax            ; move the new offset (in return address eax) into ebx
    mov     eax, request3       ; move the final part of the request into the eax register
    call    moveToMem           ; call moveToMem appending request3 onto the request bss

    mov     ecx, 0x0            ; move the null byte into ecx
    mov     [request+eax], ecx  ; append the null byte into the final position
    inc     eax

    pop     ecx
    pop     edx
    ret

;------------------------------------------
; void printReq(String domain, String port)
; Takes the domain and port and loads it into the resquest memory address
printReq:
    call    createReq       ; since the domain and and port are already in eax and ebx respectively, 
                            ; it is prepared for createReq
    mov     eax, request    ; move the request into eax
    call    sprintLF        ; print the request with linefeed

    ret

;------------------------------------------
; int writeReq(socket_t fd, String domain, String port)
; write the request to the socket and returns -1 if failure
writeReq:
    push    edx 
    push    edi
    
    mov     edi, eax        ; store the value in eax (the socket pointer) in edi
    
    mov     eax, ebx        ; move the domain (in ebx) into eax
    mov     ebx, ecx        ; move the port (in ecx) into ebx
    call    createReq       ; create the request (eax is )

    mov     edx, eax        ; move the length of the request into from the createReq into edx
    mov     ecx, request    ; move address of our request variable into ecx
    mov     ebx, edi        ; move file descriptor into ebx (created socket file descriptor)
    mov     eax, 4          ; invoke SYS_WRITE (kernel opcode 4)
    int     0x80            ; call the kernel 

    pop     edi
    pop     edx 
    ret

;------------------------------------------
; void readHttp(socket_t fd)
; Reads the data from http get request
readHttp:
    push    edi
    push    edx
    push    ecx
    push    ebx
    
    mov     edi, eax        ; move the argument in eax (the file descriptor into edi)
    
.httpReadLoop:
    mov     edx, 1          ; number of bytes to read (we will read 1 byte at a time)
    mov     ecx, buffer     ; move the memory address of our buffer variable into ecx
    mov     ebx, edi        ; move edi into ebx (created socket file descriptor)
    mov     eax, 3          ; invoke SYS_READ (kernel opcode 3)
    int     0x80            ; call the kernel

    cmp     eax, 0          ; if return value of SYS_READ in eax is zero 
    jz      .finished       ; jmp to .finished if we have reached the end of the file (zero flag set)

    mov     eax, buffer     ; move the memory address of our buffer variable into eax printing
    call    sprint          ; call our string printing function
    jmp     .httpReadLoop   ; go back over the loop

.finished:
    call    closeSocket ; close the socket

    pop     ebx
    pop     ecx
    pop     edx
    pop     edi 
    ret

;------------------------------------------
; void close(socke_t fd)
; Closes the created socket file descriptor
closeSocket:
    push    edi
    push    ebx

    mov     ebx, edi    ; move edi into ebx (connected socket file descriptor)
    mov     eax, 6      ; invoke SYS_CLOSE (kernel opcode 6)
    int     0x80        ; call the kernel

    pop     ebx
    pop     edi
    ret
%endif