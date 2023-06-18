player_width  equ 20
player_height equ 22

player_x dw tile_size * 4
player_y dd tile_size * 9
player_flip db 0
player_can_jump db 1

player_x_min    dw 3 * tile_size + tile_size / 2
player_x_max    dw 17 * tile_size - tile_size / 2
player_y_value  dd 144.0
player_y_max    dd 144.0

player_vy_value dd 0.0
player_vy_acc   dd 0.2
player_vy_jump  dd -4.0

update_player:
	; move left
	test byte [axis_left], 0xff
		jz .end_if_move_left
		mov ax, [player_x]
		mov dx, [player_x_min]
		sub ax, 2
		cmp ax, dx
			jnl .end_if_x_lt_min
			mov ax, dx
		.end_if_x_lt_min:
		mov [player_x], ax
		or byte [player_flip], 1
		jmp .end_if_move_right
	.end_if_move_left:

	; move right
	test byte [axis_right], 0xff
		jz .end_if_move_right
		mov ax, [player_x]
		mov dx, [player_x_max]
		add ax, 2
		cmp ax, dx
			jng .end_if_x_get_max
			mov ax, dx
		.end_if_x_get_max:
		mov [player_x], ax
		and byte [player_flip], 0
	.end_if_move_right:

	; jump
	test byte [space_key], 0xff
	jz .end_if_jump
	test byte [player_can_jump], 0xff
	jz .end_if_jump
		; clear can jump flag and set vy
		and byte [player_can_jump], 0
		mov eax, [player_vy_jump]
		mov [player_vy_value], eax
	.end_if_jump:

	; update vy
	test byte [player_can_jump], 0xff
	jnz .end_if_dropping
		fld dword [player_y_max]
		fld dword [player_y_value]
		fld dword [player_vy_value]
		fadd dword [player_vy_acc] ; vy += a
		fst dword [player_vy_value]
		faddp ; y += vy
		fst dword [player_y_value]
		fcomip ; if (y >= max y)
		jb .end_if_reach_ground
			; vy = 0
			fldz
			fstp dword [player_vy_value]
			; y = max y
			mov eax, [player_y_max]
			mov [player_y_value], eax
			; set can jump flag
			or byte [player_can_jump], 1
		.end_if_reach_ground:
		fstp ; pop max y (clear stack)
	.end_if_dropping:

	ret

draw_player:
	; eax = player frame * player width * player height
	mov eax, [ticks]
	shr eax, 3
	and eax, 0x07
	mov esi, player_frames
	add esi, eax
	movzx eax, byte [esi]
	mov ecx, player_width * player_height
	mul ecx

	; esi = player sprite source address
	mov esi, player_sprites
	add esi, eax

	; eax = player float number to integer
	fld dword [player_y_value]
	fistp dword [player_y]

	; edi = frame buffer target address
	mov eax, [player_y]
	mov bx, [player_x]
	sub eax, player_height
	sub bx, player_width / 2
	mov [push_frame_x], bx
	mov [push_frame_y], ax
	movsx ebx, bx
	mov ecx, video_width
	mul ecx
	add eax, ebx
	add eax, frame_buffer
	mov edi, eax

	; ebx = store frame buffer
	mov word [push_frame_w], player_width
	mov word [push_frame_h], player_height
	push edi
	call push_frame_buffer
	mov ebx, edi
	pop edi

	; edx = frame buffer row delta
	test byte [player_flip], 0xff
	jz .end_if_flipped
		add ebx, player_width - 1
		add edi, player_width - 1
		mov dword [.row_iter_func], .row_iter_flip
		mov dword [.column_iter_func], .column_iter_flip
		jmp .end_if_not_flipped
	.end_if_flipped:
		mov dword [.row_iter_func], .row_iter
		mov dword [.column_iter_func], .column_iter
	.end_if_not_flipped:

	mov ecx, player_height
	.row:
		push ecx
		mov ecx, player_width
		.column:
			; store last pixel to stack block
			mov al, [edi]
			mov [ebx], al

			; load mouse sprite pixel
			lodsb

			; skip transparent pixels
			test al, al
			jz .skip_pixel
			mov [edi], al
			.skip_pixel:

			call [.column_iter_func]
			loop .column

		; draw next row
		call [.row_iter_func]
		pop ecx
		loop .row

	ret

	.row_iter_func dd 0
	.column_iter_func dd 0

	.row_iter:
		add edi, video_width - player_width
		ret
	.row_iter_flip:
		add edi, video_width + player_width
		add ebx, player_width * 2
		ret

	.column_iter:
		inc ebx
		inc edi
		ret
	.column_iter_flip:
		dec ebx
		dec edi
		ret

player_frames db 0, 0, 0, 1, 2, 2, 2, 1

player_sprites:
incbin "../assets/player.raw"
