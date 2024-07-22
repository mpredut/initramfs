#!/bin/bash

KERNEL_DIR="linux-5.10.1"
KERNEL_IMG="$KERNEL_DIR/arch/x86_64/boot/bzImage"

INITRAMFS_DIR="initramfs"
INITRAMFS_IMG="custom_bed.img"

echo "Starting with $KERNEL_DIR and $INITRAMFS ..."
# Check if the user has execute permissions for the current directory
if [[ ! -w . ]]; then
    echo "You do not have write permissions in the current directory. Please check your permissions."
    exit 1
fi

# Function to check the success of a script execution
run_script() {
    local script=$1
    shift
    if [[ -x "$script" ]]; then
        ./"$script" "$@"
        if [[ $? -ne 0 ]]; then
            echo "Script $script failed to execute successfully."
            exit 1
        fi
    else
        echo "Script $script is not executable or not found."
        exit 1
    fi
}

# Run build_kernel.sh with KERNEL_DIR
run_script "build_kernel.sh" "$KERNEL_DIR"

# Run build_initramfs.sh with INITRAMFS_DIR
run_script "build_initramfs.sh" "$INITRAMFS_DIR" "$INITRAMFS_IMG"

# Run runqemu.sh with KERNEL_IMG and INITRAMFS_IMG
run_script "runqemu.sh" "$KERNEL_IMG" "$INITRAMFS_IMG"

echo "All scripts executed successfully."
