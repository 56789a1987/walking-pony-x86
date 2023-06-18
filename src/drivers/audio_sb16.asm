sound_sample_rate equ 22050

; DMA buffer
sound_buffer      equ frame_stack_base + video_width * 0x40
sound_buffer_size equ sound_sample_rate

; sound device state
sound_available db 0
sound_volume    db 0

; ecx > 0 - success
dsp_wait_read_buffer:
	push ax
	mov ecx, 100000
	mov dx, 0x22e
	.poll:
		in al, dx
		test al, 0xf0
		jnz .end
		loop .poll
	.end:
	pop ax
	ret

; ecx > 0 - success
dsp_wait_write_buffer:
	push ax
	mov ecx, 100000
	mov dx, 0x22c
	.poll:
		in al, dx
		test al, 0xf0
		jz .end
		loop .poll
	.end:
	pop ax
	ret

; ecx > 0 - success
dsp_wait_read_data:
	mov ecx, 100000
	mov dx, 0x22a
	.poll:
		in al, dx
		cmp al, 0xaa
		je .end
		loop .poll
	.end:
	ret

dsp_write:
	call dsp_wait_write_buffer
	mov dx, 0x22c
	out dx, al
	ret

dsp_read:
	call dsp_wait_read_buffer
	mov dx, 0x22a
	in al, dx
	ret

; init sound device
dsp_reset:
	; write a 1 to the reset port
	mov al, 1
	mov dx, 0x226
	out dx, al

	; wait for 3ms
	xor al, al
	.wait:
		dec al
		jnz .wait

	; write a 0 to the reset port
	out dx, al

	call dsp_wait_read_buffer
	test ecx, ecx
	jz .end ; fail

	call dsp_wait_read_data
	test ecx, ecx
	jz .end ; fail

	; set IRQ
	mov al, 0x80 ; set IRQ command
	mov dx, 0x224
	out dx, al

	mov al, 0x02 ; 1 - IRQ 2, 2 - IRQ 5, 4 - IRQ 7, 8 - IRQ 10
	mov dx, 0x225
	out dx, al

	; set default volume
	mov al, 0xcc
	call dsp_set_volume

	mov [sound_available], byte 1

	.end:
	ret

dsp_setup_dma:
	; disable channel 1
	mov al, 0b101 
	out 0x0a, al

	; clear the byte pointer flip-flop
	out 0x0c, al

	; channel 1, playback, auto-initialized
	mov al, 0b01011001
	out 0x0b, al

	; channel 1 address
	mov ax, sound_buffer % 0x10000
	out 0x02, al ; low byte
	mov al, ah
	out 0x02, al ; high byte

	; channel 1 size (double size for auto-initialized)
	mov ax, sound_buffer_size * 2
	out 0x03, al ; low byte
	mov al, ah
	out 0x03, al ; high byte

	; 8-bit DMA channel 1 page
	mov al, sound_buffer / 0x10000
	out 0x83, al

	; enable the sound card DMA channel
	mov al, 0b001
	out 0x0a, al

	ret

dsp_play:
	; turn on speaker
	mov al, 0xd1
	call dsp_write

	; program the DMA controller for background transfer
	call dsp_setup_dma

	; set sample rate
	mov al, 0x41 ; 41 - output rate, 42 - input rate
	call dsp_write
	mov dx, sound_sample_rate
	mov al, dh ; high byte of the sampling rate
	call dsp_write
	mov al, dl ; low byte of the sampling rate
	call dsp_write

	; write the I/O command to the DSP
	mov al, 0xc6 ; 8-bit auto-initialized output
	call dsp_write

	; write the I/O transfer mode to the DSP
	mov al, 0x00 ; mono unsigned data
	call dsp_write

	; write the block size to the DSP (Low byte/high byte)
	mov ax, sound_buffer_size
	call dsp_write ; low byte
	mov al, ah
	call dsp_write ; high byte

	ret

; FIXME: doesn't work on QEMU
dsp_set_volume:
	mov [sound_volume], al

	mov al, 0x22 ; master volume command
	mov dx, 0x224
	out dx, al

	mov al, [sound_volume]
	mov dx, 0x225
	out dx, al

	ret

sound_handler:
	call music_transfer_next
	; dsp 8-bit ack
	mov dx, 0x22e
	in al, dx
	ret
