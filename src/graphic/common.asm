; video information
video_width  equ 320
video_height equ 200
video_buffer equ 0xa0000
frame_buffer equ 0x100000 ; use double buffer

frame_stack_base  equ 0x120000
frame_stack_ptr   dd frame_stack_base

; shared variables used for arguments
draw_x dd 0
draw_y dd 0
draw_w dd 0
draw_h dd 0

; transfer frame buffer to video buffer
flush_screen:
	mov esi, frame_buffer
	mov edi, video_buffer
	mov ecx, video_width * video_height / 4
	rep movsd
	ret

; fill the whole screen, al = color
fill_screen:
	; reduce loop times by half
	mov ah, al
	mov ecx, video_width * video_height / 2
	mov edi, frame_buffer
	rep stosw
	ret

push_frame_x dw 0
push_frame_y dw 0
push_frame_w dw 0
push_frame_h dw 0

; call this directly for transferring frame buffer data later
; at drawing could improve performance
; returns: edi - frame buffer block address
push_frame_buffer:
	; frame buffer block size
	movsx eax, word [push_frame_w]
	movsx ecx, word [push_frame_h]
	mul ecx
	add eax, 8 ; meta size

	; memory to store buffer
	mov edi, [frame_stack_ptr]
	sub edi, eax
	mov [frame_stack_ptr], edi

	; write frame buffer block meta
	mov ax, [push_frame_x]
	stosw
	mov ax, [push_frame_y]
	stosw
	mov ax, [push_frame_w]
	stosw
	mov ax, [push_frame_h]
	stosw

	ret

push_frame_buffer_and_transfer:
	; edi = stack block address
	call push_frame_buffer

	; esi = frame buffer + x + y * video width
	mov esi, frame_buffer
	movsx eax, word [push_frame_x]
	add esi, eax
	movsx eax, word [push_frame_y]
	mov ecx, video_width
	mul ecx
	add esi, eax

	; eax = block width
	; edx = frame buffer row delta
	mov edx, ecx
	movsx eax, word [push_frame_w]
	sub edx, eax

	movsx ecx, word [push_frame_h]

	; transfer frame buffer data
	.row:
		push ecx
		mov ecx, eax
		rep movsb
		add esi, edx
		pop ecx
		loop .row

	ret

; pop a stacked block and transfer it to frame buffer
; returns: esi - frame stack pointer
pop_frame_buffer:
	mov esi, [frame_stack_ptr]

	; edi = base + x + y * video width
	mov edi, frame_buffer
	movsx eax, word [esi] ; x
	add edi, eax
	movsx eax, word [esi + 2] ; y
	mov ecx, video_width
	mul ecx
	add edi, eax

	; eax = block width
	; edx = frame buffer row delta
	mov edx, ecx
	movsx eax, word [esi + 4] ; width
	sub edx, eax

	movsx ecx, word [esi + 6] ; height

	add esi, 8 ; skip meta
	.row:
		push ecx
		mov ecx, eax
		rep movsb
		add edi, edx
		pop ecx
		loop .row

	mov [frame_stack_ptr], esi

	ret

pop_all_frame_buffers:
	call pop_frame_buffer
	cmp esi, frame_stack_base
	jb pop_all_frame_buffers
	ret

%include "graphic/draw_rect.asm"
%include "graphic/draw_text.asm"

%include "graphic/draw_tile.asm"
%include "graphic/draw_menu.asm"
%include "graphic/draw_mouse.asm"
%include "graphic/draw_player.asm"
