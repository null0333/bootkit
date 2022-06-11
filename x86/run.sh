#!/bin/bash

# adapted from https://wiki.osdev.org/UEFI

CFLAGS='-target x86_64-unknown-windows 
	-ffreestanding 
	-fshort-wchar 
	-mno-red-zone 
	-Ignu-efi-3.0.8/inc -Ignu-efi-3.0.8/inc/x86_64 -Ignu-efi-3.0.8/inc/protocol'
LDFLAGS='-target x86_64-unknown-windows 
	-nostdlib 
	-Wl,-entry:efi_main 
	-Wl,-subsystem:efi_application 
	-fuse-ld=lld-link'

clang $CFLAGS -c -o hello.o hello.c \
&& clang $CFLAGS -c -o data.o gnu-efi-3.0.8/lib/data.c \
&& clang $LDFLAGS -o main.efi hello.o data.o \
&& dd if=/dev/zero of=main.img bs=512 count=93750 \
&& parted main.img -s -a minimal mklabel gpt \
&& parted main.img -s -a minimal mkpart EFI FAT16 2048s 93716s \
&& parted main.img -s -a minimal toggle 1 boot \
&& dd if=/dev/zero of=/tmp/part.img bs=512 count=91669 \
&& mformat -i /tmp/part.img -h 32 -t 32 -n 64 -c 1 \
&& mcopy -i /tmp/part.img main.efi :: \
&& dd if=/tmp/part.img of=main.img bs=512 count=91669 seek=2048 conv=notrunc \
&& qemu-system-x86_64 -machine virt -cpu max \
    -bios OVMF.fd \
    -drive format=raw,file=main.img \
    -net none \
    -nographic
