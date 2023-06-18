menu_items equ 3
menu_item_width equ char_width * 15
menu_item_left  equ (video_width - menu_item_width) / 2
menu_item_right equ (video_width + menu_item_width) / 2

menu_title   db "Menu", 0
menu_info    db "Code by Polyethylene", 10, "Graphic by SomeApple", 10, " Music by SomeApple", 0
menu_active  db 0
menu_clicked db 0 ; 1 - pause button, 2 - menu button

menu_screen_y_addrs dd menu_resume_button.screen_y, menu_volume_button.screen_y, menu_exit_button.screen_y
menu_active_addrs dd menu_resume_button.active, menu_volume_button.active, menu_exit_button.active

menu_item_actions dd toggle_pause, menu_volume_button.adjust_mouse, power_off
menu_item_lr_keys dd noop_func, menu_volume_button.adjust_keyboard, noop_func

menu_resume_button:
	.draw:
		mov ebx, .attr
		mov ecx, 0
		mov edx, (video_width - char_width * 6) / 2
		mov esi, .text
		call draw_menu_button
		ret

	.text: db "Resume", 0
	.attr:
	.active db 0
	.screen_y dd 0

menu_volume_button:
	.draw:
		mov ebx, .attr
		movzx ecx, byte [sound_volume]
		and ecx, 0xf
		mov edx, (video_width - char_width * 6) / 2
		mov esi, .text
		call draw_menu_button
		ret

	.adjust_mouse:
		mov ax, [mouse_x]
		sub ax, menu_item_left - char_width / 2

		cmp ax, 0
		jnl .end_if_lt_min
		mov ax, 0
		jmp .end_if_gt_max
		.end_if_lt_min:
		cmp ax, menu_item_width
		jl .end_if_gt_max
		mov ax, menu_item_width
		.end_if_gt_max:

		shr ax, 3 ; step width

		mov cl, 0x11
		mul cl

		call dsp_set_volume

		mov al, [menu_active]
		call draw_menu_buttons

		ret

	; cl: 0 - left, 1 - right
	.adjust_keyboard:
		mov al, [sound_volume]

		test cl, cl
		jnz .end_if_left
			cmp al, 0x00
			jna .end_if_right
			sub al, 0x11
			call dsp_set_volume
			jmp .end_if_right
		.end_if_left:
			cmp al, 0xff
			jnb .end_if_right
			add al, 0x11
			call dsp_set_volume
		.end_if_right:

		ret

	.text: db "Volume", 0
	.attr:
	.active db 0
	.screen_y dd 0

menu_exit_button:
	.draw:
		mov ebx, .attr
		mov ecx, 0
		mov edx, (video_width - char_width * 9) / 2
		mov esi, .text
		call draw_menu_button
		ret

	.text: db "Power off", 0
	.attr:
	.active db 0
	.screen_y dd 0

menu_use_item:
	movsx eax, byte [menu_active]
	mov ebx, menu_item_actions
	call [ebx + eax * 4]
	ret

; cl: 0 - up, 1 - down
menu_handle_up_down_key:
	movsx eax, byte [menu_active]

	test cl, cl
	jnz .end_if_up
		dec eax
		cmp eax, 0
		jge .end_if_down
		mov eax, menu_items - 1
		jmp .end_if_down
	.end_if_up:
		inc eax
		cmp eax, menu_items
		jl .end_if_down
		mov eax, 0
	.end_if_down:

	mov [menu_active], al
	call draw_menu_buttons

	ret

; cl: 0 - left, 1 - right
menu_handle_left_right_key:
	movsx eax, byte [menu_active]
	push eax
	mov ebx, menu_item_lr_keys
	call [ebx + eax * 4]
	pop eax
	call draw_menu_buttons
	ret

menu_handle_mouse_down:
	; x in range
	mov ax, [mouse_x]
	; x < button left
	cmp ax, menu_item_left
	jl .end
	; x >= button right
	cmp ax, menu_item_right
	jnl .end

	; check y for each button
	mov ax, [mouse_y]
	mov esi, menu_screen_y_addrs
	mov ecx, 0

	.check_button:
		; dx = button y
		mov ebx, [esi + ecx * 4]
		mov dx, [ebx]

		; y < button top
		cmp ax, dx
		jl .end_if_y_in_range
		; y >= button bottom
		add dx, char_height
		cmp ax, dx
		jnl .end_if_y_in_range
			; is on the button
			mov byte [menu_clicked], 2
			mov al, cl
			mov [menu_active], al
			call draw_menu_buttons
			jmp .end
		.end_if_y_in_range:

		inc cl
		cmp cl, menu_items
		jb .check_button

	.end:
	ret

menu_handle_mouse_up:
	; is from menu button
	cmp byte [menu_clicked], 2
	jne .end
	mov byte [menu_clicked], 0

	; x in range
	mov ax, [mouse_x]
	; x < button left
	cmp ax, menu_item_left
	jl .end
	; x >= button right
	cmp ax, menu_item_right
	jnl .end

	; dx = active button y
	mov ax, [mouse_y]
	movzx ecx, byte [menu_active]
	mov esi, menu_screen_y_addrs
	mov ebx, [esi + ecx * 4]
	mov dx, [ebx]

	; y < button top
	cmp ax, dx
	jl .end
	; y >= button bottom
	add dx, char_height
	cmp ax, dx
	jnl .end

	call menu_use_item

	.end:
	ret

; pause button

pause_button_left   equ tile_size * 19
pause_button_bottom equ tile_size

pause_button_handle_mouse_down:
	mov ax, [mouse_x]
	; x < button left
	cmp ax, pause_button_left
	jl .end

	mov ax, [mouse_y]
	; y >= button bottom
	cmp ax, pause_button_bottom
	jnl .end

	mov byte [menu_clicked], 1

	.end:
	ret

pause_button_handle_mouse_up:
	; is from pause button
	cmp byte [menu_clicked], 1
	jne .end
	mov byte [menu_clicked], 0

	mov ax, [mouse_x]
	; x < button left
	cmp ax, pause_button_left
	jl .end

	mov ax, [mouse_y]
	; y >= button bottom
	cmp ax, pause_button_bottom
	jnl .end

	call toggle_pause

	.end:
	ret
