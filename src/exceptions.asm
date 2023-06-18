%macro exception_handler 1
	%1_handler:
	begin_interrupt
	mov esi, %1
	call draw_exception
	end_interrupt
%endmacro

exception_message db "Something went wrong... qwp", 0

exception_00 db "Division Error", 0
exception_01 db "Debug", 0
exception_02 db "Non-maskable Interrupt", 0
exception_03 db "Breakpoint", 0

exception_04 db "Overflow", 0
exception_05 db "Bound Range Exceeded", 0
exception_06 db "Invalid Opcode", 0
exception_07 db "Device Not Available", 0

exception_08 db "Double Fault", 0
exception_09 db "Coprocessor Segment Overrun", 0
exception_0a db "Invalid TSS", 0
exception_0b db "Segment Not Present", 0

exception_0c db "Stack-Segment Fault", 0
exception_0d db "General Protection Fault", 0
exception_0e db "Page Fault", 0
exception_0f db "", 0 ; reserved

exception_10 db "x87 Floating-Point Exception", 0
exception_11 db "Alignment Check", 0
exception_12 db "Machine Check", 0
exception_13 db "SIMD Floating-Point Exception", 0

exception_14 db "Virtualization Exception", 0
exception_15 db "Control Protection Exception", 0
exception_16:
exception_17:

exception_18:
exception_19:
exception_1a:
exception_1b db "", 0 ; reserved

exception_1c db "Hypervisor Injection Exception", 0
exception_1d db "VMM Communication Exception", 0
exception_1e db "Security Exception", 0
exception_1f db "", 0 ; reserved

exception_handler exception_00
exception_handler exception_01
exception_handler exception_02
exception_handler exception_03

exception_handler exception_04
exception_handler exception_05
exception_handler exception_06
exception_handler exception_07

exception_handler exception_08
exception_handler exception_09
exception_handler exception_0a
exception_handler exception_0b

exception_handler exception_0c
exception_handler exception_0d
exception_handler exception_0e
exception_handler exception_0f

exception_handler exception_10
exception_handler exception_11
exception_handler exception_12
exception_handler exception_13

exception_handler exception_14
exception_handler exception_15
exception_handler exception_16
exception_handler exception_17

exception_handler exception_18
exception_handler exception_19
exception_handler exception_1a
exception_handler exception_1b

exception_handler exception_1c
exception_handler exception_1d
exception_handler exception_1e
exception_handler exception_1f

draw_exception:
	push dword [draw_x]
	push dword [draw_y]

	mov al, 0
	mov al, ah
	mov edi, frame_buffer
	mov ecx, char_height * video_width
	rep stosw

	mov ah, 0x28 ; red

	; show error message
	mov dword [draw_x], 0
	mov dword [draw_y], char_height
	call draw_string

	; show title
	mov dword [draw_x], 0
	mov dword [draw_y], 0
	mov esi, exception_message
	call draw_string

	; force a flush to show the message
	call flush_screen

	pop dword [draw_y]
	pop dword [draw_x]

	; TODO: return control back
	.end:
	hlt
	jmp .end
