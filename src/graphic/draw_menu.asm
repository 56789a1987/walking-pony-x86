menu_width   equ 200
menu_height  equ 96

draw_menu:
	; pause button
	draw_one_tile 19, 0, 0x1f
	test byte [paused], 0xff
	jz .end

	; menu background
	mov al, 0x00
	draw_rect (video_width - menu_width) / 2 + 4, (video_height - menu_height) / 2 + 4, menu_width, menu_height
	mov al, 0x01
	sub dword [draw_x], 4
	sub dword [draw_y], 4
	call fill_rect
	mov al, 0x0f
	add dword [draw_x], 3
	add dword [draw_y], 3
	sub dword [draw_w], 6
	sub dword [draw_h], 6
	call fill_rect
	mov al, 0x01
	add dword [draw_x], 1
	add dword [draw_y], 1
	sub dword [draw_w], 2
	sub dword [draw_h], 2
	call fill_rect

	; menu title
	mov ah, 0x0f
	mov dword [draw_x], (video_width - char_width * 4) / 2
	add dword [draw_y], 4
	mov esi, menu_title
	call draw_string

	mov ah, 0x09
	mov dword [draw_x], (video_width - char_width * 20) / 2
	add dword [draw_y], 16
	mov esi, menu_info
	call draw_string

	; resume button
	add dword [draw_y], 16
	mov eax, [draw_y]
	mov [menu_resume_button.screen_y], eax

	; volume button
	add dword [draw_y], 12
	mov eax, [draw_y]
	mov [menu_volume_button.screen_y], eax

	; exit button
	add dword [draw_y], 12
	mov eax, [draw_y]
	mov [menu_exit_button.screen_y], eax

	mov eax, 0
	mov [menu_active], al
	call draw_menu_buttons

	.end:
	ret

; ebx - data, ecx - progress, edx - text left, draw y
draw_menu_button:
	; button background
	mov eax, [ebx + 1]
	mov dword [draw_x], menu_item_left
	mov dword [draw_y], eax
	mov dword [draw_w], menu_item_width
	mov dword [draw_h], char_width

	; button color
	mov eax, 0x100807
	test byte [ebx], 0xff
	jz .end_if_active
		mov eax, 0x0f040c
		jmp .end_if_not_active
	.end_if_active:
		mov eax, 0x100807
	.end_if_not_active:

	call fill_rect

	; button progress
	test ecx, ecx
		jz .skip_progress
		mov al, ah
		shl ecx, 3
		mov [draw_w], ecx
		call fill_rect
	.skip_progress:

	; button text
	shr eax, 8
	mov [draw_x], edx
	call draw_string
	ret

; eax - active item
draw_menu_buttons:
	mov ebx, menu_active_addrs
	mov ecx, 0
	.set_button_active:
		cmp eax, ecx
		jne .end_if_active
			mov edi, [ebx + ecx * 4]
			mov byte [edi], 1
			jmp .end_if_not_active
		.end_if_active:
			mov edi, [ebx + ecx * 4]
			mov byte [edi], 0
		.end_if_not_active:

		inc ecx
		cmp ecx, 3
		jl .set_button_active

	call menu_resume_button.draw
	call menu_volume_button.draw
	call menu_exit_button.draw
	ret
