org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

; 22:44

; FAT 12 headers
; ##############
jmp short start
nop

bdb_oem:                 db 'MSWIN4.1' ; 8 bytes
bdb_bytes_per_sector:    dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors:    dw 1
bdb_fat_count:           db 2
bdb_dir_entries_count:   dw 0E0h
bdb_total_sectors:       dw 2880
bdb_media_descriptor_type: db 0F0h
bdb_sectors_per_fat:       dw 9
bdb_sectors_per_track:     dw 18
bdb_heads:                 dw 2
bdb_hidden_sectors:        dd 0
bdb_large_sector_count:    dd 0

; extended boot record
ebr_drive_number:       db 0 ; 0x00 floppy, 0x80 hdd
                        db 0

ebr_signature:          db 29h
ebr_volume_id:          db 12h, 34h, 56h, 78h ; serial number, value doesnt matter
ebr_volume_label:       db 'LOGOS OS   ' ; 11 bytes, padded with spaces
ebr_system_id:          db 'FAT12   ' ;8 bytes
; ############

; code begins here
; ################

start:
    jmp main

; prints a string to the screen
; params:
;   -ds:si points to string
puts:
    push si
    push ax

.loop:
    lodsb ; loads next character in al
    or al, al ; check if next char is null
    jz .done ; jumps to dest if 0 flag is present
    ;jmp .loop

    mov ah, 0x0e ; call bios interrupt
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    pop ax
    pop si
    ret


main:

    ; setting up all the data segments
    mov ax, 0 ; cant write to ds/es directly so set general purpose register to 0
    mov ds, ax ; now copy the 0 into ds
    mov es, ax ; and es

    ; setup stack pointers
    mov ss, ax
    mov sp, 0x7C00 ; stack grows downwards from where we are loaded in memory

    ; read something from disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl
    mov ax, 1 ; LBA=1, second sector from disk
    mov cl, 1 ;1 sector to read
    mov bx, 0x7E00 ;data should be after the bootloader
    call disk_read
    ; print message
    mov si, msg_hello
    call puts

    hlt

; ERROR handling
; ##############
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot
    hlt

wait_key_and_reboot:
    mov ah, 0
    int 16h ;wait for keypress
    jmp 0FFFFh: 0 ; beginning of bios, reboot

.halt:
    cli ; disable interrupts so CPU doesnt get out of halt state
    hlt

; ##############

; Disk routines
; #############

; converts an lba address to chs
; Params:
;   - ax: LBA address
; Returns:
;   - cx (bits 0-5): sector number
;   - cx (bits 6-15): cylinder
;   - dh: head

lba_to_chs:
    push ax
    push dx


    xor dx, dx ; dx=0
    div word [bdb_sectors_per_track] ; ax= LBA / SectorsPerTrack

    inc dx ; dx= LBA % SectorsPerTrack + 1
    mov cx, dx ; cx = sector

    xor dx, dx ; dx=0
    div word [bdb_heads] ; ax= (LBA / SectorsPerTrack / Heads = cylinder
                         ; dx = (LBA / SectorsPertrack) % Heads = head

    mov dh, dl ; dl = head
    mov ch, al ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah ;put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al ;restore dl
    pop ax
    ret

; Reads sectors from a disk
; Params:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
disk_read:
    push ax ; save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx ; temporarily save CL (number of sectors to read)
    call lba_to_chs
    pop ax ; AL= number of sectors to read

    mov ah, 02h
    mov di, 3 ; since floppy disks are unreliable, documentation suggests
              ; retrying at least 3 times

.retry:
    pusha ; save all registers, we dont know what bios modifies
    stc ; set carry flag, some BIOS don't set it
    int 13h ; carry flag cleared equals success
    jnc .done ; jump if carry not set

    dec di
    test di, di
    jnz .retry

.fail:
    ; all attempts exhausted
    jmp floppy_error

.done:
    popa

    push di ; restore registers modified
    push dx
    push cx
    push bx
    push ax
    ret

; resets disk controller
; Params:
;   dl: drive number
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


; #############

msg_hello: db 'Booting OS...', ENDL, 'Welcome to...', ENDL, ' _     ___   ____  ___  ____     ___  ____', ENDL, '| |   / _ \ / ___|/ _ \/ ___|   / _ \/ ___|', ENDL, '| |  | | | | |  _| | | \___ \  | | | \___ \
', ENDL, '| |__| |_| | |_| | |_| |___) | | |_| |___) |', ENDL, '|_____\___/ \____|\___/|____/   \___/|____/ ', ENDL, ENDL, '@user/home/ ~~:> ' , 0
msg_read_failed: db '<Critical Error> Failed to read from disk', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h