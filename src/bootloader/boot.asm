org 0x7C00
bits 16

; macro defining end line hex code
%define ENDL 0x0D, 0x0A

;
; FAT12 header
;

;https://wiki.osdev.org/FAT#Boot_Record  <-- check info
;BPB (BIOS Parameter Block)

jmp short start
nop

bpb_oem:                    db 'MSWIN4.1'           ; 8 bytes
bpb_bytes_per_sector:       dw 512
bpb_sectors_per_cluster:    db 1
bpb_reserved_sectors:       dw 1
bpb_fat_count:              db 2
bpb_dir_entries_count:      dw 0E0h
bpb_total_sectors:          dw 2880                 ;2880 * 512 = 1.44MB
bpb_media_descriptor_type:  db 0F0h                 ;F0 =3.5" floppy disk
bpb_sectors_per_fat:        dw 9                    ;9 sectors/fat
bpb_sectors_per_track:      dw 18
bpb_heads:                  dw 2
bpb_hidden_sectors:         dd 0
bpb_large_sector_count:     dd 0

# Extended Boot Record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hard drive, useless
                            db 0                    ; reserved
ebr_signiature:             db 29h
ebr_volume_id:              db 22h, 22h, 22h, 22h   ; value doesn't matter
ebr_volume_label:           db 'OSDEV LEARN'        ; 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 bytes, padded with spaces

start:
    jmp main

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