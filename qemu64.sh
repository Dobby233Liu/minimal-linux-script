#!/bin/sh

# 运行qemu，vga模式，内存128m，cdrom为minimal_linux_live.iso
qemu-system-x86_64 -m 128M -cdrom minimal_linux_live.iso -boot d -vga std