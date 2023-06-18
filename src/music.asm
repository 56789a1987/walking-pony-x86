; decoded sound data
sound_notes      equ sound_buffer + sound_buffer_size * 2 + 0x80
sound_data       equ sound_notes + 0x80
sound_data_size  equ sound_sample_rate * 6 ; 6 seconds
sound_data_block dd 1 ; the first two blocks are transfered at initialization

music_decode:
	; skip instrument byte
	mov ecx, ft_s0p0c1 - (ft_s0p0c0 + 1)
	mov esi, ft_s0p0c0 + 1
	mov edi, sound_notes

	mov bl, 1 ; compressed durations mode

	jmp .read_note

	.compressed_durations_off:
		mov bl, 0
		jmp .read_next

	.compressed_durations_on:
		mov bl, 1
		jmp .read_next

	.repeat_note:
		push ecx
		movzx ecx, dl
		rep stosb
		pop ecx

		inc esi
		dec ecx

		jmp .read_next

	.read_note:
		lodsb

		; command bytes
		cmp al, 0x82
		je .compressed_durations_off
		cmp al, 0x84
		je .compressed_durations_on

		; store note
		stosb

		; is compressed durations
		test bl, bl
		jz .read_next

		mov dl, [esi]
		jnz .repeat_note

		.read_next:
		loop .read_note

	mov ecx, 0
	mov esi, sound_notes
	mov edi, sound_data

	.write_data:
		push ecx

		; address = music length (0x40) * ecx / data_size
		mov eax, ecx
		mov ecx, 0x42
		mul ecx
		xor edx, edx
		mov ecx, sound_data_size
		div ecx

		; note
		movzx ebx, byte [esi + eax]

		; is note-off
		mov al, 0
		cmp bl, 0x7f
		je .next

		; frequency
		sub ebx, 22
		shl ebx, 1
		movzx eax, byte [ebx + frequency_map]

		; get time again
		pop ecx
		mov ebx, ecx
		push ecx

		; sawtooth wave data = 256 * frequency * time / sample_rate
		shl eax, 8
		mul ebx
		mov ecx, sound_sample_rate
		xor edx, edx
		div ecx

		; to 1/4 square wave al = (al & 0xc0 ? 0x00 : 0x80)
		test al, 0xc0
			jz .end_if_high
			; is the second part
			mov al, 0x00
			jmp .end_if_low
		.end_if_high:
			; is the first part
			mov al, 0x80
		.end_if_low:

		.next:
		stosb
		pop ecx

		inc ecx
		cmp ecx, sound_data_size
		jb .write_data

	; transfer the first two blocks
	mov ecx, sound_buffer_size / 2
	mov esi, sound_data
	mov edi, sound_buffer
	rep movsd

	ret

music_transfer_next:
	mov ebx, [sound_data_block]
	inc ebx

	mov eax, ebx
	mov ecx, sound_buffer_size
	mul ecx

	; should reset position
	cmp eax, sound_data_size
		jb .end_reset_ptr
		mov eax, 0
		mov ebx, 0
	.end_reset_ptr:

	mov [sound_data_block], ebx

	mov esi, sound_data
	add esi, eax

	test ebx, 1
		jz .end_if_even
		; even block
		mov edi, sound_buffer
		jmp .end_if_odd
	.end_if_even:
		; odd block
		mov edi, sound_buffer + sound_buffer_size
	.end_if_odd:

	; transfer the block
	mov ecx, sound_buffer_size / 4
	rep movsd

	ret

music_play:
	mov al, [sound_available]
	test al, al
	jz .end ; no sb16 device

	call music_decode
	call dsp_play

	.end:
	ret

frequency_map:
	dw 0x37, 0x3a, 0x3e, 0x41, 0x45, 0x49, 0x4e, 0x52, 0x57, 0x5c, 0x62, 0x68
	dw 0x6e, 0x75, 0x7b, 0x83, 0x8b, 0x93, 0x9c, 0xa5, 0xaf, 0xb9, 0xc4, 0xd0
	dw 0xdc, 0xe9, 0xf7, 0x106, 0x115, 0x126, 0x137, 0x14a, 0x15d, 0x172, 0x188, 0x19f

%include "../assets/music.asm"
