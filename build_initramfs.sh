#!/bin/bash

# Set the path for initramfs
INITRAMFS_DIR="./initramfs"
BUSYBOX_PATH="/bin/busybox"  # Change this path if BusyBox is not in /bin
INIT_SCRIPT_PATH="./init"    # Path to your prepared init script

# List of files to be copied for each category
COMMON_LIBS=(
    "/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
    "/lib/x86_64-linux-gnu/libc.so.6"
    "/lib/x86_64-linux-gnu/libpthread.so.0"
    "/lib/x86_64-linux-gnu/libdl.so.2"
)

PARTED_LIBS=(
    "/usr/lib/libparted.so.2"
    "/lib/x86_64-linux-gnu/libuuid.so.1"
    "/lib/x86_64-linux-gnu/libblkid.so.1"
    "/lib/x86_64-linux-gnu/libcom_err.so.2"
    "/lib/x86_64-linux-gnu/libe2p.so.2"
    "/lib/x86_64-linux-gnu/libext2fs.so.2"
    "/lib/x86_64-linux-gnu/libss.so.2"
    "/lib/x86_64-linux-gnu/libdevmapper.so.1.02.1"
)

LINUX_LIBS=(
    "/lib/x86_64-linux-gnu/libm.so.6"
    "/lib/x86_64-linux-gnu/libtinfo.so.6"
    "/lib/x86_64-linux-gnu/libselinux.so.1"
    "/usr/lib/x86_64-linux-gnu/libreadline.so.8"
    "/usr/lib/x86_64-linux-gnu/libpcre2-8.so.0"
    "/usr/lib/x86_64-linux-gnu/libudev.so.1"
)

# Function to check if a file exists
check_file_exists() {
    if [ ! -f "$1" ]; then
        echo "Error: File $1 not found."
        exit 1
    fi
}

# Check if BusyBox and init script exist
check_file_exists "$BUSYBOX_PATH"
check_file_exists "$INIT_SCRIPT_PATH"

# Clean and recreate the initramfs directory structure
echo "Cleaning and creating initramfs directory structure..."
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/{bin,sbin,etc,proc,sys,dev,lib,lib64,usr/{bin,lib,lib64},mnt,run,var}

# Copy BusyBox and create necessary symbolic links
echo "Copying BusyBox to $INITRAMFS_DIR/bin..."
cp "$BUSYBOX_PATH" "$INITRAMFS_DIR/bin/"
cd "$INITRAMFS_DIR/bin" || exit 1
echo "Creating symbolic links for BusyBox commands..."
ln -s busybox sh
ln -s busybox ls
ln -s busybox mount
ln -s busybox echo
ln -s busybox init
ln -s busybox switch_root
./busybox --install
cd - || exit 1

# Copy necessary dependencies for BusyBox
echo "Copying necessary dependencies for BusyBox..."
ldd "$BUSYBOX_PATH" | grep "=>" | awk '{print $3}' | while read -r lib; do
    lib_dir=$(dirname "$lib")
    mkdir -p "$INITRAMFS_DIR/$lib_dir"
    echo "Copying $lib to $INITRAMFS_DIR/$lib_dir"
    cp -v "$lib" "$INITRAMFS_DIR/$lib_dir"
done

# Copy common libraries
echo "Copying common libraries..."
for lib in "${COMMON_LIBS[@]}"; do
    lib_dir="$INITRAMFS_DIR$(dirname "$lib")"
    mkdir -p "$lib_dir"
    echo "Copying $lib to $lib_dir"
    cp -v "$lib" "$lib_dir"
done

# Copy parted libraries
echo "Copying parted libraries..."
for lib in "${PARTED_LIBS[@]}"; do
    lib_dir="$INITRAMFS_DIR$(dirname "$lib")"
    mkdir -p "$lib_dir"
    echo "Copying $lib to $lib_dir"
    cp -v "$lib" "$lib_dir"
done

# Copy linux libraries
echo "Copying linux libraries..."
for lib in "${LINUX_LIBS[@]}"; do
    lib_dir="$INITRAMFS_DIR$(dirname "$lib")"
    mkdir -p "$lib_dir"
    echo "Copying $lib to $lib_dir"
    cp -v "$lib" "$lib_dir"
done

# Copy the prepared init script
echo "Copying init script to $INITRAMFS_DIR/init..."
cp "$INIT_SCRIPT_PATH" "$INITRAMFS_DIR/init"
chmod +x "$INITRAMFS_DIR/init"

# Build initramfs and create the custom_bed.img file
echo "Building initramfs..."
cd "$INITRAMFS_DIR" || exit 1
find . -print0 | cpio --null -ov --format=newc > ../custom_bed.img
cd - || exit 1

echo "Compressing initramfs image..."
#gzip -f ../custom_bed.img

echo "Initramfs image created successfully: custom_bed.img.gz"

