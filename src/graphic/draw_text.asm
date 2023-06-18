char_width equ 8
char_height equ 8

; ah - color, al - char, draw x, draw y
draw_char:
	push eax
	push ecx
	push esi
	push edi

	sub al, 0x20 ; offset

	push ax
	; get sprite address esi = base + code * 8
	movzx eax, al
	shl eax, 3
	mov esi, font_sprites
	add esi, eax

	; edi = target address
	mov eax, [draw_y]
	mov ecx, video_width
	mul ecx
	add eax, [draw_x]
	mov edi, frame_buffer + char_width
	add edi, eax

	; restore color stored in ax
	pop ax

	mov ecx, char_height
	.row:
		push ecx
		mov al, [esi]
		mov ecx, char_width
		.column:
			test al, 1
				jz .skip_plot
				mov [edi], ah
			.skip_plot:
			dec edi
			shr al, 1
			loop .column

		inc esi
		add edi, video_width + char_width
		pop ecx
		loop .row

	pop edi
	pop esi
	pop ecx
	pop eax
	ret

; esi - string address, ah - color, draw x, draw y
draw_string:
	push eax
	push ecx
	mov ecx, [draw_x]

	.char:
		lodsb

		; end of string \0
		test al, al
		jz .end

		; line wrap \n
		cmp al, 0x0a
			jne .end_if_is_wrap
			add dword [draw_y], char_height
			mov [draw_x], ecx
			jmp .char
		.end_if_is_wrap:

		; skip space
		cmp al, " "
			je .end_if_not_space
			call draw_char
		.end_if_not_space:

		add dword [draw_x], char_width
		jmp .char

	.end:
	pop ecx
	pop eax
	ret

; eax - value, bl - color, draw x, draw y
draw_number_right:
	push eax
	push ecx
	push edx

	mov ecx, 10

	.loop:
		xor edx, edx
		div ecx

		push eax
		mov ah, bl
		mov al, dl
		add al, "0"
		call draw_char
		sub dword [draw_x], char_width
		pop eax

		test eax, eax
		jnz .loop

	pop edx
	pop ecx
	pop eax
	ret

; eax - value, cl - color, draw x, draw y
draw_number_hex_right:
	push eax

	.loop:
		mov esi, eax
		and esi, 0xf
		add esi, .chars

		push eax
		mov ah, cl
		mov al, [esi]
		call draw_char
		sub dword [draw_x], char_width
		pop eax

		shr eax, 4
		test eax, eax
		jnz .loop

	pop eax
	ret

	.chars db "0123456789ABCDEF"

font_sprites:
incbin "../assets/font.raw"
