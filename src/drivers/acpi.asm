acpi_command     dd 0
acpi_enable      db 0
acpi_disable     db 0
acpi_pm1a_ctrl   dd 0
acpi_pm1b_ctrl   dd 0

slp_type_a dw 0
slp_type_b dw 0

; finds the ACPI header and returns the address of the RSDT
; returns: eax - RSDT address
search_rsdp:
	mov esi, 0xe0000
	mov ecx, 0x20000 / 4

	.search_loop:
		cmp dword [esi], "RSD "
		jne .search_next
		cmp dword [esi + 4], "PTR "
		je .checksum

		.search_next:
		add esi, 4
		loop .search_loop

	; RSDP not found / RSDT not valid
	.fail:
	mov eax, 0
	ret

	.checksum:
		mov eax, 0
		mov dl, 0
		.checksum_loop:
			mov dh, byte [esi + eax]
			add dl, dh
			inc eax
			cmp eax, 20 ; RSDPtr size
			jne .checksum_loop
		test dl, dl
		jnz .search_next

	; RSDP found, get RSDT address
	mov eax, [esi + 16]

	; check if RSDT address is correct (ACPI is available)
	mov esi, eax
	cmp dword [esi], "RSDT"
	jne .fail

	ret

; eax - RSDT address
; returns: eax - DSDT address
search_facp:
	mov esi, eax

	; number of entries = (*(RSDT + 1) + 36) / 4
	mov eax, [esi + 4] 
	sub eax, 36
	shr eax, 2
	test eax, eax
	jz .fail ; no entries
	mov ecx, eax

	; skip header information
	add esi, 36

	.search_loop:
		; check if the desired table is reached
		mov edi, [esi]
		cmp dword [edi], "FACP"
		je .facp_found

		add esi, 4
		loop .search_loop

	; FACP not found / valid
	.fail:
	mov eax, 0
	ret

	.facp_found:
	mov esi, [edi + 40]
	cmp dword [esi], "DSDT"
	jne .fail ; DSDT is not valid

	; edi = FACP address, esi = DSDT address
	mov eax, [edi + 48]
	mov [acpi_command], eax
	mov al, [edi + 52]
	mov [acpi_enable], al
	mov al, [edi + 53]
	mov [acpi_disable], al
	mov eax, [edi + 64]
	mov [acpi_pm1a_ctrl], eax
	mov eax, [edi + 68]
	mov [acpi_pm1b_ctrl], eax

	mov eax, esi
	ret

; eax - DSDT address
; returns: eax - S5 address
search_s5:
	mov esi, eax
	mov ecx, [esi + 4]

	; skip header
	add esi, 36
	sub ecx, 36

	.search_loop:
		cmp dword [esi], "_S5_"
		je .s5_found

		inc esi
		loop .search_loop

	; S5 not found / valid
	.fail:
	mov eax, 0
	ret

	.s5_found:
	; check if S5 was found
	test ecx, ecx
	jz .fail

	; check for valid AML structure
	mov al, [esi + 4]
	cmp al, 0x12
	jne .fail

	mov al, [esi - 1]
	cmp al, 0x08
	je .parse

	mov ax, [esi - 2]
	cmp ax, 0x5c08
	jne .fail

	.parse:
	add esi, 5

	; calculate PkgLength size
	mov al, [esi]
	and al, 0xc0
	shr al, 6
	movzx eax, al
	add esi, eax
	add esi, 2

	; skip byte prefix
	cmp byte [esi], 0x0a
		jne .end_if_skip_1
		inc esi
	.end_if_skip_1:

	mov ax, [esi]
	shl ax, 10
	or ax, 0x2000
	mov [slp_type_a], ax

	inc esi

	; skip byte prefix
	cmp byte [esi], 0x0a
		jne .end_if_skip_2
		inc esi
	.end_if_skip_2:

	mov ax, [esi]
	shl ax, 10
	or ax, 0x2000
	mov [slp_type_b], ax

	ret

enable_acpi:
	mov dx, [acpi_pm1a_ctrl]

	; check if already enabled
	in ax, dx
	test ax, 1
	jnz .end

	; send enable acpi command
	mov dx, [acpi_command]
	mov al, [acpi_enable]
	out dx, al

	.end:
	ret

init_acpi:
	call search_rsdp
	test eax, eax
	jz .end

	call search_facp
	test eax, eax
	jz .end

	call search_s5
	test eax, eax
	jz .end

	call enable_acpi

	.end:
	ret

power_off:
	; check supported
	mov ax, [acpi_command]
	test ax, ax
	jz .end

	; send the shutdown command
	mov ax, [slp_type_a]
	mov dx, [acpi_pm1a_ctrl]
	out dx, ax

	mov ax, [slp_type_b]
	test ax, ax
	jz .end

	mov dx, [acpi_pm1b_ctrl]
	out dx, ax

	.end:
	ret

reboot:
	cli

	; write to output
	call keyboard_wait
	mov al, 0xd1
	out 0x64, al

	; keyboard reset
	call keyboard_wait
	mov al, 0xfe
	out 0x60, al

	.wait:
		hlt
		jmp .wait
