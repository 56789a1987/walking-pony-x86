; timer speed / fps
mov al, 0x36
out 0x43, al
mov ax, 1193180 / 60
out 0x40, al
mov al, ah
out 0x40, al

; initialize interrupts and drivers
call enable_a20
call setup_interrupts
call init_acpi
call init_mouse
call init_rtc
call dsp_reset
; enable interrupts
sti

; main
call [draw_map_func]
call music_play

main_end:
	hlt
	jmp main_end

; interrupt handlers
timer_handler:
	test byte [paused], 0xff
	jnz .not_paused
		call update_player
		call draw_player
		inc dword [ticks]
	.not_paused:

	call draw_mouse
	call flush_screen

	call pop_all_frame_buffers
	ret

toggle_pause:
	xor byte [paused], 1
	call [draw_map_func]
	ret

noop_func:
	ret

draw_map_func dd draw_home_map
map_handle_up_func dd home_map_handle_up

ticks  dd 0
paused db 0

%include "boot/a20.asm"
%include "idt.asm"
%include "exceptions.asm"

%include "drivers/acpi.asm"
%include "drivers/ps2_keyboard.asm"
%include "drivers/ps2_mouse.asm"
%include "drivers/rtc.asm"
%include "drivers/audio_sb16.asm"

%include "menu.asm"
%include "music.asm"

%include "graphic/common.asm"

%include "maps/home_map.asm"
%include "maps/outside_map.asm"
