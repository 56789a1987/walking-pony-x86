bits 16
org 0x7c00

origin equ 0x7c00

%include "boot/bpb.asm"
%include "boot/gdt.asm"

boot:
	; clear segment registers
	xor ax, ax
	mov ds, ax
	mov es, ax

	; set video mode = 320x200 256
	mov al, 0x13
	int 0x10

	; load kernel from disk
	; NOTE: the extended doesn't support floppy disk
	; mov si, dap  ; ds:si - segment:offset pointer to the DAP
	; mov ah, 0x42 ; extended read sectors from drive
	; int 0x13

	mov ax, [dap.segmnt]
	mov es, ax

	; load kernel from disk
	mov ah, 0x02 ; function 02
	mov al, 0x40 ; sectors to read
	mov cx, 0x02 ; cylinder:sector
	mov dh, 0 ; head
	mov bx, 0
	int 0x13

	; test A20 support
	clc
	mov ax, 0x2403
	int 0x15
	jc .skip_a20
	test ah, ah
	jnz .skip_a20
	mov [a20_support], bx
	.skip_a20:

	; switch to protected mode
	cli
	lgdt [gdt_descriptor]
	mov eax, cr0
	or eax, 0x1
	mov cr0, eax

	; begin 32-bit
	jmp CODE_SEG:init_32bit

; DAP
dap:
	db 0x10 ; size of DAP = 0x10
	db 0x00 ; unused, should be zero
	.sector dw 0x24 ; number of sectors to be read, 0x7d * 512 = 64000
	.offset dw 0x00 ; target memory buffer offset
	.segmnt dw (origin + main - $$) >> 4 ; target memory buffer segment
	.lba    dq 0x01 ; start LBA

a20_support dw 0

bits 32

init_32bit:
	; set segment registers
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov ebp, 0x90000
	mov esp, ebp

	call main

boot_end:
	hlt
	jmp boot_end

; boot sector signature
times 510 - ($ - $$) db 0
dw 0xaa55

main:
%include "main.asm"
