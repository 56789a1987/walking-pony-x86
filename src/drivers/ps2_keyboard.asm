keyboard_lock_state db 0
keyboard_ext_code   db 0

space_key  db 0
axis_left  db 0
axis_right db 0

keyboard_wait:
	in al, 0x64
	test al, 2
	jnz keyboard_wait
	ret

keyboard_handler:
	in al, 0x60

	; has extended code
	test byte [keyboard_ext_code], 0xff
	jnz .handler_2

	cmp al, 0xe0
	jne .not_extend_1
	mov [keyboard_ext_code], al
	jmp .end
	.not_extend_1:

	cmp al, 0xe1
	jne .not_extend_2
	mov [keyboard_ext_code], al
	jmp .end
	.not_extend_2:

	; escape pressed
	cmp al, 0x01
	jne .not_escape
	call toggle_pause
	jmp .end
	.not_escape:

	; E pressed
	cmp al, 0x12
	jne .not_e
	; exception handler test
	xor eax, eax
	xor ecx, ecx
	xor edx, edx
	div ecx
	jmp .end
	.not_e:

	; enter pressed
	cmp al, 0x1c
	jne .not_enter
	test byte [paused], 0xff
	jz .not_paused_enter
		call menu_use_item
	.not_paused_enter:
	jmp .end
	.not_enter:

	; space pressed
	cmp al, 0x39
	jne .not_space
	or byte [space_key], 1
	jmp .end
	.not_space:

	; space released
	cmp al, 0xb9
	jne .not_space_release
	and byte [space_key], 0
	jmp .end
	.not_space_release:

	.end:
	ret

.handler_2:
	mov byte [keyboard_ext_code], 0

	; up pressed
	cmp al, 0x48
	jne .not_up
	; handle paused menu commands
	test byte [paused], 0xff
	jz .not_paused_up
		mov cl, 0
		call menu_handle_up_down_key
		jmp .end_not_paused_up
	.not_paused_up:
		call [map_handle_up_func]
	.end_not_paused_up:
	jmp .end
	.not_up:

	; down pressed
	cmp al, 0x50
	jne .not_down
	; handle paused menu commands
	test byte [paused], 0xff
	jz .not_paused_down
		mov cl, 1
		call menu_handle_up_down_key
	.not_paused_down:
	jmp .end
	.not_down:

	; left pressed
	cmp al, 0x4b
	jne .not_left
	; handle paused menu commands
	test byte [paused], 0xff
	jz .not_paused_left
		mov cl, 0
		call menu_handle_left_right_key
	.not_paused_left:
	; handle main control
	or byte [axis_left], 1
	jmp .end
	.not_left:

	; right pressed
	cmp al, 0x4d
	jne .not_right
	; handle paused menu commands
	test byte [paused], 0xff
	jz .not_paused_right
		mov cl, 1
		call menu_handle_left_right_key
	.not_paused_right:
	; handle main control
	or byte [axis_right], 1
	jmp .end
	.not_right:

	; left released
	cmp al, 0xcb
	jne .not_left_release
	and byte [axis_left], 0
	jmp .end
	.not_left_release:

	; right released
	cmp al, 0xcd
	jne .not_right_release
	and byte [axis_right], 0
	jmp .end
	.not_right_release:

	ret
