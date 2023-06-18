mouse_wait_input:
	mov ecx, 100000
	.poll:
		in al, 0x64
		test al, 1
		jnz .end
		loop .poll
	.end:
	ret

mouse_wait_output:
	mov ecx, 100000
	.poll:
		in al, 0x64
		test al, 2
		jz .end
		loop .poll
	.end:
	ret

; ah = value
mouse_write:
	call mouse_wait_output
	; tell the mouse we are sending a command
	mov al, 0xd4
	out 0x64, al
	call mouse_wait_output
	; finally write
	mov al, ah
	out 0x60, al
	ret

mouse_read:
	; get response from mouse
	call mouse_wait_input
	in al, 0x60
	ret

init_mouse:
	; enable the auxiliary mouse device
	call mouse_wait_output
	mov al, 0xa8
	out 0x64, al

	; get status
	call mouse_wait_output
	mov al, 0x20
	out 0x64, al

	; enable the interrupts
	call mouse_wait_input
	in al, 0x60
	or al, 0b10 ; set bit 1 (enable IRQ12)
	push ax

	; get status
	call mouse_wait_output
	mov al, 0x60
	out 0x64, al

	; send to mouse
	call mouse_wait_output
	pop ax
	out 0x60, al

	; use default settings
	mov ah, 0xf6
	call mouse_write
	call mouse_read

	; enable the mouse
	mov ah, 0xf4
	call mouse_write
	call mouse_read

	ret

mouse_handler:
	; status
	in al, 0x64
	test al, 0x01
	jnz .p0
	ret

	.p0:
		; data byte
		in al, 0x60
		mov dl, [mouse_count]

		; mouse buttons
		cmp dl, 0
		jne .p1

		mov cl, [mouse_flags]
		mov [mouse_flags], al

		; left button pressed
		test cl, 1
		jnz .not_mouse_down
		test al, 1
		jz .not_mouse_down
		call mouse_down_handler
		jmp .not_mouse_up
		.not_mouse_down:

		; left button released
		test cl, 1
		jz .not_mouse_up
		test al, 1
		jnz .not_mouse_up
		call mouse_up_handler
		.not_mouse_up:

		mov [mouse_count], byte 1
		ret

	.p1:
		; delta x
		cmp dl, 1
		jne .p2

		mov cx, [mouse_x]
		movsx dx, al
		add cx, dx

		; clamp x to screen
		cmp cx, 0
			jnl .end_if_x_lt_min
			mov cx, 0
		.end_if_x_lt_min:
		cmp cx, video_width
			jl .end_if_x_gt_max
			mov cx, video_width
		.end_if_x_gt_max:

		mov [mouse_x], cx
		mov [mouse_count], byte 2
		ret

	.p2:
		; delta y
		mov cx, [mouse_y]
		movsx dx, al
		sub cx, dx

		; clamp y to screen
		cmp cx, 0
			jnl .end_if_y_lt_min
			mov cx, 0
		.end_if_y_lt_min:
		cmp cx, video_height
			jl .end_if_y_gt_max
			mov cx, video_height
		.end_if_y_gt_max:

		mov [mouse_y], cx
		mov [mouse_count], byte 0
		ret

mouse_down_handler:
	call pause_button_handle_mouse_down

	; handle pause menu commands
	test byte [paused], 0xff
	jz .not_paused
	call menu_handle_mouse_down
	.not_paused:

	ret

mouse_up_handler:
	call pause_button_handle_mouse_up

	; handle pause menu commands
	test byte [paused], 0xff
	jz .not_paused
	call menu_handle_mouse_up
	.not_paused:

	ret

mouse_packet dd 0
mouse_count db 0

; put the mouse at bottom right by default
mouse_x dw video_width
mouse_y dw video_height
mouse_flags db 0
