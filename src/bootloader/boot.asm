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

    ; read something from floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    mov ax, 1                                   ; LBA=1, second sector from disk
    mov cl, 1                                   ; 1 sector to read
    mov bx, 0x7E00                              ; data should be after the bootloader
    call disk_read


    ; print message
    mov si, msg_hello
    call puts

    cli
    hlt
    
    ;
    ; Error handlers
    ;

    floppy_error:
        mov si, msg_read_failed
        call puts
        jmp wait_key_and_reboot
        

    wait_key_and_reboot:
        mov ah, 0
        int 16h                                 ; wait for keypress
        jmp 0FFFFh:0                            ; jump to beginning of BIOS, should reboot


    
    .halt:
        cli                                     ; disable interrupts
        hlt


;
; Disk Routines
; for reading from the disk


; https://en.wikipedia.org/wiki/Logical_block_addressing#CHS_conversion
;
; Convertsan LBA (Logical block adressing) to a CHS(Cylinder head sector)
; Parameters:
;   - ax: LBA address
; Returns;
;   - cx [bits 0-5]: sector number
;   - cx [bits 5-15]: cylinder
;   - dh: head
;
lba_to_chs:
    push ax
    push dx

    xor dx, dx                          ; dx =0
    div word [bpb_sectors_per_track]    ; ax = LBA / SectorsPerTrack
                                        ; dx = LBA % SectorsPerTrack

    inc dx                              ; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                          ; cx = sector

    xor dx, dx                          ; dx = 0
    div word [bpb_heads]                ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                        ; dx = (LBA / SectorsPerTrack) % Heads = head
    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylinder (lower 8 bits)
    shl ah, 6                           
    or cl, ah                           ; put upper 2 bits of cylinder in cl

    pop ax                              ; restore ax
    mov dl, al                          ; restore dl
    pop ax
    ret
    
;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - es:bx memory address where to store read data

disk_read:

    push ax                             ; save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             ; temporary saves CL (number of sectors to read)
    call lba_to_chs                     ; compute CHS
    pop ax                              ; AL = number of sectors to read

    mov ah, 02h

    ; retry 3 times because floppy disks are unreliable
    mov di, 3                           ; retry count
    .retry:
        pusha                           ; save all registers, we don't know what bios modifies
        stc                          ; set carry flag, some bios'es don't set it
        int 13h                         ; if carry flag is cleared, the operation was a success
        jnc .done                       ; jump if carry not set

        ; read failed
        popa
        call disk_reset

        dec di
        test di, di                     ; if di not zero jump to loop beginning
        jnz .retry

    .fail:
        ; all attempts are exhausted
        jmp floppy_error

    .done:
        popa


        pop di                             ; restore modified registers 
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;
; Disk Reset
; Resets disk controller
; Parameters:
;   dl : Drive number

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

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
msg_hello:                               db 'Hello world!', ENDL , 0 

; floppy_error message
msg_read_failed:                         db 'Read from disk failed!', ENDL , 0 


; set bytes required for boot
; the BIOS expects the last two bytes of the first sector to be AA55h
times 510-($-$$) db 0
dw 0AA55h