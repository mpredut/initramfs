#!/bin/bash

# Directory to store the kernel and initramfs
DIR="arch_linux_qemu"
ISO_URL="https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"
ISO_FILE="$DIR/archlinux.iso"
MOUNT_DIR="$DIR/mount"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.1.tar.xz"
KERNEL_TAR="linux-5.10.1.tar.xz"
KERNEL_DIR="linux-5.10.1"

# Create the directory if it doesn't exist
mkdir -p $DIR

# Download the Arch Linux ISO if it doesn't exist
if [[ ! -f "$ISO_FILE" ]]; then
    echo "Downloading Arch Linux ISO..."
    wget -O $ISO_FILE $ISO_URL
fi

# Mount the ISO to extract the initramfs
mkdir -p $MOUNT_DIR
sudo mount -o loop $ISO_FILE $MOUNT_DIR

if [[ ! -f "$DIR/initramfs-linux.img" ]]; then
    echo "Copying initramfs..."
    cp $MOUNT_DIR/arch/boot/x86_64/initramfs-linux.img $DIR/initramfs-linux.img
fi

# Unmount the ISO
sudo umount $MOUNT_DIR
rmdir $MOUNT_DIR

# Download and extract the Linux kernel source
if [[ ! -d "$KERNEL_DIR" ]]; then
    echo "Downloading Linux kernel source..."
    wget $KERNEL_URL
    tar -xf $KERNEL_TAR
fi

# Add the "hello world" message to the kernel code in the start_kernel function
echo "Adding 'hello world' message to the kernel code..."
if ! grep -q 'printk(KERN_INFO "hello world\\n");' $KERNEL_DIR/init/main.c; then
    sed -i '/printk("Kernel command line/ a printk(KERN_INFO "hello world\\n");' $KERNEL_DIR/init/main.c
fi

# Configure and build the kernel
cd $KERNEL_DIR
echo "Configuring and building the kernel..."
#make defconfig
#make -j$(nproc)
cd ..

# Copy the compiled kernel
cp $KERNEL_DIR/arch/x86_64/boot/bzImage $DIR/vmlinuz-linux

# Create an empty disk image
DISK_IMAGE="disk_for_qemu.img"
echo "Creating an empty disk image..."
qemu-img create -f qcow2 $DISK_IMAGE 1G
#check_error


# Start QEMU with the specified kernel and initramfs
#qemu-system-x86_64 -kernel $KERNEL_DIR/arch/x86_64/boot/bzImage  -initrd "custom_bed.img" -append "console=ttyS0 init=/init" -hda $DISK_IMAGE -m 512M -nographic -drive file=$DISK_IMAGE,if=none,id=drive0 -device ahci,id=ahci -device ide-drive,drive=drive0,bus=ahci.0
qemu-system-x86_64 -kernel $KERNEL_DIR/arch/x86_64/boot/bzImage  -initrd "custom_bed.img" -append "console=ttyS0 init=/init noapic" --hda $DISK_IMAGE -m 512M -nographic 


#-drive file=disk.qcow2,if=none,id=drive0 -device ahci,id=ahci -device ide-drive,drive=drive0,bus=ahci.0
#qemu-system-x86_64 -kernel $KERNEL_DIR/arch/x86_64/boot/bzImage -initrd "initramfs.img" -append "console=ttyS0 init=/init noapic"  -m 512M -nographic
#qemu-system-x86_64 -kernel $KERNEL_DIR/arch/x86_64/boot/bzImage -initrd "$DIR/initramfs-linux.img" -append "console=ttyS0 init=/init"  -m 512M -nographic
