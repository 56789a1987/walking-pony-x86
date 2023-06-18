NASM  := nasm
QEMU  := qemu-system-x86_64
SRC   := ./src
ENTRY := boot.asm
BIN   := boot.img

all: build

build:
	$(NASM) -I$(SRC) $(SRC)/$(ENTRY) -o $(BIN)

# SB16 audio playback freezes emulation in QEMU when using GTK display
# See https://forum.osdev.org/viewtopic.php?f=1&t=39652
run: build
	$(QEMU) -drive file=$(BIN),format=raw -device sb16 -display sdl -accel kvm

clean:
	$(RM) $(BIN)

.PHONY: run clean
