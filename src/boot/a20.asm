; test A20 in protected mode
test_a20:
	mov edi, 0x114514 ; odd megabyte address
	mov esi, 0x014514 ; even megabyte address

	; making sure that both addresses contain diffrent values
	mov [esi], esi
	; if A20 line is cleared the two pointers would point to
	; the address esi that would contain edi
	mov [edi], edi
	cmpsd
	; if not equivalent , A20 line is set
	jne .is_enabled

	; if equivalent, A20 line is cleared
	mov al, 0
	ret

	.is_enabled:
	mov al, 1
	ret

enable_a20_keyboard:
	; disable keyboard
	call keyboard_wait
	mov al, 0xad
	out 0x64, al

	; read from input
	call keyboard_wait
	mov al, 0xd0
	out 0x64, al

	call keyboard_wait
	in al, 0x60
	push ax

	; write to output
	call keyboard_wait
	mov al, 0xd1
	out 0x64, al

	call keyboard_wait
	pop ax
	or al, 2
	out 0x60, al

	; enable keyboard
	call keyboard_wait
	mov al, 0xae
	out 0x64, al

	call keyboard_wait
	ret

enable_a20_fast_gate:
	in al, 0x92
	test al, 2
	jnz .skip

	or al, 2
	out 0x92, al

	.skip:
	ret

enable_a20:
	call test_a20
	test al, al
	jnz .end

	mov ax, [a20_support]
	test ax, ax
	jz .end

	; supports fast gate
	test ax, 2
	jz .fallback
	call enable_a20_fast_gate

	call test_a20
	test al, al
	jnz .end

	; fallback to use keyboard controller
	.fallback:
	call enable_a20_keyboard

	.end:
	ret
