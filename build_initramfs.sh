#!/bin/bash

# Check if the correct number of parameters was passed
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <KERNEL_DIR> <INITRAMFS_IMG_NAME>"
    exit 1
fi

INITRAMFS_DIR="$1"
INITRAMFS_IMG_NAME="$2"

# Check if INITRAMFS_DIR exists and delete it if it does
if [[ -d $INITRAMFS_DIR ]]; then
    echo "Directory $INITRAMFS_DIR exists. Deleting..."
    rm -rf "$INITRAMFS_DIR" || { echo "Failed to delete $INITRAMFS_DIR"; exit 1; }
fi

# Create directory structure
mkdir -p "$INITRAMFS_DIR"/{sbin,etc,mnt,proc,run,sys,usr/{bin,sbin,lib64,lib/x86_64-linux-gnu},var}

# Copy the init file from the current directory to $INITRAMFS_DIR
cp -v ./init $INITRAMFS_DIR

# Create a minimal init file in /sbin/init
cat << 'EOF' > "$INITRAMFS_DIR/sbin/init"
#!/bin/sh
# Mount necessary file systems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /run

# Execute minimal shell (BusyBox)
exec /bin/sh
EOF
chmod +x "$INITRAMFS_DIR/sbin/init"

# Ensure the init file is executable
chmod +x "$INITRAMFS_DIR/sbin/init"
cd $INITRAMFS_DIR

# Create symbolic links
ln -s usr/bin bin
ln -s usr/lib lib
ln -s usr/lib64 lib64
cd ..

# Function to copy necessary libraries for a binary
copy_libs() {
    local binary=$1
    local libs=$(ldd $binary | grep "=>" | awk '{print $3}')
    for lib in $libs; do
        dest_dir=$INITRAMFS_DIR$(dirname $lib)
        mkdir -p $dest_dir
        cp -v $lib $dest_dir
    done
}

# List of binaries (busybox, gparted and mkfs)
BINARIES=($(which busybox) $(which parted) $(which mkfs) $(which mkfs.ext4) $(which udevadm))

for bin in "${BINARIES[@]}"; do
    copy_libs $bin
    cp -v $bin $INITRAMFS_DIR$bin
done

echo "Directory structure and necessary files have been successfully copied."

# Copy necessary libraries
cp -v $(find /usr/lib -name libc.so.6) "$INITRAMFS_DIR/usr/lib/x86_64-linux-gnu/"
cp -v $(find /usr/lib -name ld-2.31.so) "$INITRAMFS_DIR/usr/lib/x86_64-linux-gnu/"
cp -v $(find /usr/lib -name ld-2.31.so) "$INITRAMFS_DIR/lib/x86_64-linux-gnu/"
cp -v $(find /usr/lib64 -name ld-linux-x86-64.so.2) "$INITRAMFS_DIR/usr/lib64/"
cp -v $(find /usr/lib64 -name ld-linux-x86-64.so.2) "$INITRAMFS_DIR/lib64/"

# Creating symbolic links for BusyBox commands...
cd "$INITRAMFS_DIR/bin" || exit 1
echo "Creating symbolic links for BusyBox commands..."
ln -s busybox sh
ln -s busybox echo
ln -s busybox ls
ln -s busybox cp
ln -s busybox mount
ln -s busybox switch_root
cd ..
#./busybox --install -s

#build the initramfs image from files and folder structure ...
find . -print0 | cpio --null -ov --format=newc > "../$INITRAMFS_IMG_NAME"

exit 0
