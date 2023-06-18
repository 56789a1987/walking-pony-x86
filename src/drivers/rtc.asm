rtc_second db 0
rtc_minute db 0
rtc_hour   db 0
rtc_day    db 0 ; day of week, 1 = Sunday
rtc_date   db 0 ; date of month
rtc_month  db 0
rtc_year   db 0

%macro CLOCK_READ 2
	mov al, %1
	call rtc_read
	mov [%2], al
%endmacro

; al - registration
; returns: al - value
rtc_read:
	out 0x70, al
	in al, 0x71
	ret

; al - registration, ah - value
rtc_write:
	out 0x70, al
	mov al, ah
	out 0x71, al
	ret

rtc_color db 0

clock_handler:
	mov al, 0x0c
	call rtc_read
	test al, 0x10
	jz .end

	CLOCK_READ 0x00, rtc_second
	CLOCK_READ 0x02, rtc_minute
	CLOCK_READ 0x04, rtc_hour
	CLOCK_READ 0x06, rtc_day
	CLOCK_READ 0x07, rtc_date
	CLOCK_READ 0x08, rtc_month
	CLOCK_READ 0x09, rtc_year

	.end:
	ret

init_rtc:
	mov al, 0x0b
	call rtc_read
	or  al, 0b00010110 ; update ended interrupts | binary mode | 24-hour format
	and al, 0b10011111 ; no periodic interrupt | no alarm interrupt

	mov ah, al
	mov al, 0x0b
	call rtc_write

	mov al, 0x0c
	call rtc_read

	ret
