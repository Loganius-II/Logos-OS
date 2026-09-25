org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

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

    ; print message
    mov si, msg_hello
    call puts

    hlt

.halt:
    jmp .halt

msg_hello: db 'Booting OS...', ENDL, 'Welcome to...', ENDL, ' _     ___   ____  ___  ____     ___  ____', ENDL, '| |   / _ \ / ___|/ _ \/ ___|   / _ \/ ___|', ENDL, '| |  | | | | |  _| | | \___ \  | | | \___ \
', ENDL, '| |__| |_| | |_| | |_| |___) | | |_| |___) |', ENDL, '|_____\___/ \____|\___/|____/   \___/|____/ ', ENDL, ENDL, '@user/home/ ~~:> ' , 0

times 510-($-$$) db 0
dw 0AA55h