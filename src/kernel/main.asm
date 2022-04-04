org 0x7C00
bits 16

; macro defining end line hex code
%define ENDL 0x0D, 0x0A

main:

    ; setup data segments
    mov ax, 0           ; can't write to ds/es directaly
    mov ds, ax
    mov es, ax

    ; setup stack
    mov ss, ax
    mov sp, 0x7C00

    ; print message
    mov si, msg_hello
    call puts

    hlt

    ; in case the cpu get out of HLT start this infinite loop
    .halt:
        jmp .halt
    

; FUNCTION
; prints a string to the screen using the BIOS
; params:
;   - ds:si points to string
;
puts:
    ; save registers we will modify
    push si
    push ax

    .loop:
        lodsb           ; loads next character from ds:si into al, then increment si by the amount of bytes loaded
        or al, al       ; verify if next character is null,  if zero, set the zero flag
        jz .done        ; jumps to destination if zero flag set

        ; setup BIOS interrupt
        ; setting al with ASCII char is also needed but was done above wit loadsb
        mov ah, 0x0E     ; write characters in TTY mode (TODO: search what TTY mode means)
        mov bh, 0       ; set page number (it's needed, just put 0) 
        int 0x10        ; call BIOS video interrupt
        jmp .loop
    
    .done:
        ; return registers values
        pop si
        pop ax
        ret


; creates string, remember ENDL is a macro, 0 for delimiting string length
msg_hello db 'Hello world!', ENDL , 0 



; set bytes required for boot
; the BIOS expects the last two bytes of the first sector to be AA55h
times 510-($-$$) db 0
dw 0AA55h