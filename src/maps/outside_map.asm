setup_outside_map:
	mov word [player_x], 4 * tile_size

	mov ax, [.min_x]
	mov [player_x_min], ax
	mov ax, [.max_x]
	mov [player_x_max], ax

	mov eax, [.max_y]
	mov [player_y_value], eax
	mov [player_y_max], eax

	ret

	.min_x dw tile_size / 2
	.max_x dw 20 * tile_size - tile_size / 2
	.max_y dd 160.0

draw_outside_map:
	; background
	mov edi, frame_buffer

	mov al, 0x4e
	mov ah, al
	mov ecx, video_width * 56 / 2
	rep stosw

	mov al, 0x4d
	mov ah, al
	mov ecx, video_width * 56 / 2
	rep stosw

	mov al, 0x66
	mov ah, al
	mov ecx, video_width * 56 / 2
	rep stosw

	; ground
	mov dword [draw_x], 0
	mov dword [draw_y], 10
	mov byte [tile_type], 0x21
	mov ecx, 20
	.loop_1:
		call draw_tile
		inc dword [draw_x]
		loop .loop_1
	
	mov dword [draw_x], 0
	mov dword [draw_y], 11
	mov byte [tile_type], 0x20
	mov ecx, 20
	.loop_2:
		call draw_tile
		mov dword [draw_y], 12
		call draw_tile
		mov dword [draw_y], 11
		inc dword [draw_x]
		loop .loop_2

	; house
	mov dword [draw_x], 1
	mov dword [draw_y], 7
	mov esi, .tiles_house
	mov ecx, 6
	.loop_3:
		mov al, [esi]
		mov [tile_type], al
		call draw_tile
		mov dword [draw_y], 8
		mov al, [esi + 6]
		mov [tile_type], al
		call draw_tile
		mov dword [draw_y], 9
		mov al, [esi + 12]
		mov [tile_type], al
		call draw_tile
		mov dword [draw_y], 7
		inc esi
		inc dword [draw_x]
		loop .loop_3

	draw_one_tile 3, 8, 0x1b ; door top
	draw_one_tile 4, 8, 0x1c

	; house roof
	mov byte [tile_no_grid], 1
	mov dword [draw_x], 0
	mov dword [draw_y], 5 * tile_size + tile_size / 2
	mov esi, .tiles_roof
	mov ecx, 8
	.loop_4:
		mov al, [esi]
		mov [tile_type], al
		call draw_tile
		mov dword [draw_y], 6 * tile_size + tile_size / 2
		mov al, [esi + 8]
		mov [tile_type], al
		call draw_tile
		mov dword [draw_y], 5 * tile_size + tile_size / 2
		inc esi
		add dword [draw_x], tile_size
		loop .loop_4
	mov byte [tile_no_grid], 0

	; draw name
	mov dword [draw_x], 0
	mov dword [draw_y], 0
	mov ah, 0xf
	mov esi, .name
	call draw_string

	; pause menu
	call draw_menu

	ret
	.name db "Outside", 0
	.tiles_house:
		db 0x22, 0x23, 0x23, 0x23, 0x23, 0x24
		db 0x22, 0x23, 0x23, 0x23, 0x23, 0x24
		db 0x22, 0x23, 0x1d, 0x1e, 0x23, 0x24

	.tiles_roof:
		db 0x00, 0x26, 0x25, 0x25, 0x25, 0x25, 0x27, 0x00
		db 0x26, 0x25, 0x25, 0x25, 0x25, 0x25, 0x25, 0x27

outside_map_handle_up:
	; door left <= x < door right
	movsx eax, word [player_x]
	cmp eax, 3 * tile_size
	jl .end
	cmp eax, 5 * tile_size
	jnl .end

	mov eax, [player_y]
	cmp eax, 9 * tile_size
	jl .end

	switch_to_map home_map

	.end:
	ret
