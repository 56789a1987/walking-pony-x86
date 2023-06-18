; draw a tile, x = 0-19, y = 0-14, type = 0-13
tile_size equ 16
tile_type db 0
tile_no_grid db 0

%macro draw_one_tile 3
	mov dword [draw_x], %1
	mov dword [draw_y], %2
	mov byte [tile_type], %3
	call draw_tile
%endmacro

draw_tile:
	push eax
	push ecx
	push esi
	push edi

	movzx eax, byte [tile_type]
	shl eax, 8

	; esi = pointer of the sprite data
	mov esi, tile_sprites
	add esi, eax

	; edi = pointer of the frame buffer to fill
	mov eax, [draw_y]
	mov ebx, [draw_x]
	test byte [tile_no_grid], 0xff
	jnz .not_grid
		shl eax, 4
		shl ebx, 4
	.not_grid:
	mov ecx, video_width
	mul ecx
	add eax, ebx
	add eax, frame_buffer
	mov edi, eax

	mov ecx, tile_size
	.row:
		push ecx
		mov ecx, tile_size
		.column:
			lodsb

			; skip transparent pixels
			test al, al
			jz .skip_pixel
			mov [edi], al
			.skip_pixel:

			inc edi
			loop .column

		add edi, video_width - tile_size
		pop ecx
		loop .row

	pop edi
	pop esi
	pop ecx
	pop eax
	ret

tile_sprites:
incbin "../assets/tiles.raw"
