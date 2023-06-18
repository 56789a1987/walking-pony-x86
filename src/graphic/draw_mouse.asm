mouse_size equ 12

draw_mouse:
	mov esi, mouse_sprite

	; edi = frame buffer target address
	mov ax, word [mouse_y]
	mov bx, word [mouse_x]
	mov [push_frame_x], bx
	mov [push_frame_y], ax
	movsx eax, ax
	movsx ebx, bx
	mov ecx, video_width
	mul ecx
	add eax, ebx
	add eax, frame_buffer
	mov edi, eax

	; ebx = store frame buffer
	mov ax, mouse_size
	mov [push_frame_w], ax
	mov [push_frame_h], ax
	push edi
	call push_frame_buffer
	mov ebx, edi
	pop edi

	; dx = max x for cropping
	mov dx, word [mouse_x]
	add dx, mouse_size - video_width + 1

	mov ecx, mouse_size
	.row:
		push ecx
		mov ah, 0
		mov ecx, mouse_size
		.column:
			; store last pixel to stack block
			mov al, [edi]
			mov [ebx], al

			; load mouse sprite pixel
			lodsb

			; crop right
			cmp cx, dx
			jl .skip_pixel

			; skip transparent pixels
			test al, al
			jz .skip_pixel
			cmp al, 0xc

			; make the color darker when the left button is pressed
			jne .skip_darken
			test byte [mouse_flags], 1
			jz .skip_darken
			mov al, 0x4
			.skip_darken:

			; draw pixel
			mov [edi], al
			.skip_pixel:

			inc ah
			inc ebx
			inc edi
			loop .column

		; draw next row
		add edi, video_width - mouse_size
		pop ecx
		loop .row

	ret

mouse_sprite:
incbin "../assets/mouse.raw"
