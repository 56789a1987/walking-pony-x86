pci_bus      dd 0
pci_device   dd 0
pci_function dd 0
pci_offset   dd 0

pci_write_address:
	; configuration address
	; eax = (bus << 16) | (device << 11) | (function << 8) | offset | 0x80000000
	mov eax, [pci_bus]
	shl eax, 16
	mov ecx, [pci_device]
	shl ecx, 11
	or  eax, ecx
	mov ecx, [pci_function]
	shl ecx, 8
	or  eax, ecx
	or  eax, [pci_offset]
	or  eax, 0x80000000

	; write out the address
	mov dx, 0xcf8
	out dx, eax

	ret

; returns: eax - data
pci_read:
	call pci_write_address

	; read in the data
	mov dx, 0xcfc
	in eax, dx
	ret

; eax - value
pci_write:
	push eax
	call pci_write_address
	pop eax

	; write out the data
	mov dx, 0xcfc
	out dx, eax
	ret

pci_get_vendor_id:
	mov dword [pci_offset], 0
	call pci_read
	ret

pci_get_class_id:
	mov dword [pci_offset], 0x8
	call pci_read
	ret

; edi: bus - device - function - base address
pci_store_bar:
	push eax
	; store base address
	call pci_read
	and eax, 0xfffffff0
	mov [edi], eax
	pop eax
	ret

pci_store_bar_io:
	push eax
	; store base address
	call pci_read
	and ax, 0xfffc
	mov [edi], ax

	pop eax
	ret

pci_enable_bus_master:
	push eax
	mov dword [pci_offset], 0x04
	call pci_read
	or eax, 0b110
	call pci_write
	pop eax
	ret

pci_enable_bus_master_io:
	push eax
	mov dword [pci_offset], 0x04
	call pci_read
	or eax, 0b101
	call pci_write
	pop eax
	ret

pci_probe:
	mov dword [draw_y], char_height * 4

	mov eax, 0
	.loop_bus:
		mov ebx, 0
		.loop_device:
			mov [pci_bus], eax
			mov [pci_device], ebx
			push eax

			call pci_get_vendor_id
			; vendor == 0xffff, non-existent device
			cmp ax, 0xffff
			je .end_if_exist

			call pci_get_class_id

			.end_if_exist:

			pop eax

			inc ebx
			cmp ebx, 32
			jb .loop_device
		inc eax
		cmp eax, 256
		jb .loop_bus
	ret
