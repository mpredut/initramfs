#!/bin/bash

# Check if the correct number of parameters was passed
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <KERNEL_DIR> <INITRAMFS>"
    exit 1
fi

# Check if we have qemu-system-x86_64
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "qemu-system-x86_64 could not be found. Please install."
    exit 1
fi

KERNEL_IMG="$1"
INITRAMFS_IMG="$2"

# Create an empty disk image attashed to qemu
DISK_IMAGE="disk_for_qemu.img"
echo "Creating an empty disk image..."
qemu-img create -f qcow2 $DISK_IMAGE 1G

# Start QEMU with the specified kernel and initramfs
#qemu-system-x86_64 -kernel $KERNEL_DIR/arch/x86_64/boot/bzImage  -initrd "custom_bed.img" -append "console=ttyS0 init=/init" -hda $DISK_IMAGE -m 512M -nographic -drive file=$DISK_IMAGE,if=none,id=drive0 -device ahci,id=ahci -device ide-drive,drive=drive0,bus=ahci.0
qemu-system-x86_64 -kernel "$KERNEL_IMG"  -initrd "$INITRAMFS_IMG" -append "console=ttyS0 init=/init noapic" --hda $DISK_IMAGE -m 512M -nographic 
#-drive file=disk.qcow2,if=none,id=drive0 -device ahci,id=ahci -device ide-drive,drive=drive0,bus=ahci.0
exit 0