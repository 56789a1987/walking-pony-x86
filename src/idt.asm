
%macro begin_interrupt 0
	pusha
%endmacro

%macro end_interrupt 0
	mov al, 0x20
	out 0xa0, al
	out 0x20, al
	popa
	iret
%endmacro

%macro interrupt_desc 1
	dw (origin + %1 - $$) & 0xffff ; offset low
	dw 0x8 ; code segment selector in GDT or LDT
	db 0x0 ; unused, set to 0
	db 0x8e ; gate type = interrupt gate
	dw (origin + %1 - $$) >> 16 ; offset high
%endmacro

setup_interrupts:
	lidt [idt_descriptor]

	; remap the IRQs
	; ICW1
	mov al, 0x11
	out 0x20, al
	out 0xa0, al

	; ICW2
	mov al, 0x20 ; IRQ0-IRQ7 -> interrupts 0x20-0x27
	out 0x21, al
	mov al, 0x28 ; IRQ8-IRQ15 -> interrupts 0x28-0x2F
	out 0xa1, al

	; ICW3
	mov al, 0x04
	out 0x21, al
	mov al, 0x02
	out 0xa1, al

	; ICW4
	mov al, 0x01
	out 0x21, al
	out 0xa1, al

	; mask
	mov al, 0x00
	out 0x21, al
	out 0xa1, al

	ret

empty_handler:
	begin_interrupt
	end_interrupt

timer_handler_wrap:
	begin_interrupt
	call timer_handler
	end_interrupt

clock_handler_wrap:
	begin_interrupt
	call clock_handler
	end_interrupt

keyboard_handler_wrap:
	begin_interrupt
	call keyboard_handler
	end_interrupt

mouse_handler_wrap:
	begin_interrupt
	call mouse_handler
	end_interrupt

sound_handler_wrap:
	begin_interrupt
	call sound_handler
	end_interrupt
	iret

idt_start:
	; exceptions
	interrupt_desc exception_00_handler
	interrupt_desc exception_01_handler
	interrupt_desc exception_02_handler
	interrupt_desc exception_03_handler
	interrupt_desc exception_04_handler
	interrupt_desc exception_05_handler
	interrupt_desc exception_06_handler
	interrupt_desc exception_07_handler
	interrupt_desc exception_08_handler
	interrupt_desc exception_09_handler
	interrupt_desc exception_0a_handler
	interrupt_desc exception_0b_handler
	interrupt_desc exception_0c_handler
	interrupt_desc exception_0d_handler
	interrupt_desc exception_0e_handler
	interrupt_desc exception_0f_handler
	interrupt_desc exception_10_handler
	interrupt_desc exception_11_handler
	interrupt_desc exception_12_handler
	interrupt_desc exception_13_handler
	interrupt_desc exception_14_handler
	interrupt_desc exception_15_handler
	interrupt_desc exception_16_handler
	interrupt_desc exception_17_handler
	interrupt_desc exception_18_handler
	interrupt_desc exception_19_handler
	interrupt_desc exception_1a_handler
	interrupt_desc exception_1b_handler
	interrupt_desc exception_1c_handler
	interrupt_desc exception_1d_handler
	interrupt_desc exception_1e_handler
	interrupt_desc exception_1f_handler
	; programmable interrupt timer
	interrupt_desc timer_handler_wrap
	; keyboard on PS/2
	interrupt_desc keyboard_handler_wrap
	; cascaded signals from IRQs 8–15
	interrupt_desc empty_handler
	; COM2
	interrupt_desc empty_handler
	; COM1
	interrupt_desc empty_handler
	; LPT2 (Sound Blaster 16)
	interrupt_desc sound_handler_wrap
	; floppy disk
	interrupt_desc empty_handler
	; LPT1
	interrupt_desc empty_handler
	; CMOS real-time clock
	interrupt_desc clock_handler_wrap
	; open interrupt/available / SCSI / NIC
	interrupt_desc empty_handler
	; open interrupt/available / SCSI / NIC
	interrupt_desc empty_handler
	; open interrupt/available / SCSI / NIC
	interrupt_desc empty_handler
	; mouse on PS/2
	interrupt_desc mouse_handler_wrap
	; CPU co-processor / FPU / Inter-processor
	interrupt_desc empty_handler
	; primary ATA channel
	interrupt_desc empty_handler
	; secondary ATA channel
	interrupt_desc empty_handler
idt_end:

idt_descriptor:
	dw idt_end - idt_start
	dd idt_start
