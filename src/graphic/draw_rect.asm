%macro draw_rect 4
	mov dword [draw_x], %1
	mov dword [draw_y], %2
	mov dword [draw_w], %3
	mov dword [draw_h], %4
	call fill_rect
%endmacro

; al = color
fill_rect:
	push eax
	push ebx
	push ecx
	push edx

	push ax

	; edi = base + x + y * video width
	mov edi, frame_buffer
	add edi, [draw_x]
	mov eax, [draw_y]
	mov ecx, video_width
	mul ecx
	add edi, eax

	; ebx = width, edx = video width - width
	mov edx, ecx
	mov ebx, [draw_w]
	sub edx, ebx

	mov ecx, [draw_h]
	pop ax

	.row:
		push ecx
		mov ecx, ebx
		rep stosb
		add edi, edx
		pop ecx
		loop .row

	pop edx
	pop ecx
	pop ebx
	pop eax

	ret
