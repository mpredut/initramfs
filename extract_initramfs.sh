# Directory to store the kernel and initramfs
DIR="arch_linux_qemu"
ISO_URL="https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"
ISO_FILE="$DIR/archlinux.iso"
MOUNT_DIR="$DIR/mount"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.1.tar.xz"
KERNEL_TAR="linux-5.10.1.tar.xz"
KERNEL_DIR="linux-5.10.1"
ROOTFS_DIR="$DIR/rootfs"

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

# Method 1: Extract initramfs from ISO
if [[ ! -f "$DIR/initramfs-linux.img" ]]; then
    echo "Copying initramfs (Method 1: Extract from ISO)..."
    cp $MOUNT_DIR/arch/boot/x86_64/initramfs-linux.img $DIR/initramfs-linux.img
    echo "Extracting initramfs using unmkinitramfs..."
    mkdir -p $DIR/initramfs_extracted_from_iso
    unmkinitramfs $DIR/initramfs-linux.img $DIR/initramfs_extracted_from_iso
    echo "initramfs has been extracted from ISO and unpacked to: $DIR/initramfs_extracted_from_iso"
fi

# Unmount the ISO
sudo umount $MOUNT_DIR
rmdir $MOUNT_DIR

# Method 2: Generate initramfs using mkinitramfs
echo "Generating initramfs using mkinitramfs (Method 2)..."

# Ensure that mkinitramfs is available
if ! command -v mkinitramfs &> /dev/null; then
    echo "mkinitramfs could not be found. Please install it and try again."
    exit 1
fi

# Create a root filesystem directory
mkdir -p $ROOTFS_DIR

# Here, you would normally install a minimal root filesystem.
# For simplicity, let's assume you have a prebuilt root filesystem tarball.
# You can create a minimal root filesystem using debootstrap or any other tool
# appropriate for your distribution.
ROOTFS_TARBALL_URL="http://example.com/path/to/rootfs.tar.gz"
ROOTFS_TARBALL="$DIR/rootfs.tar.gz"

# Download the root filesystem tarball if it doesn't exist
if [[ ! -f "$ROOTFS_TARBALL" ]]; then
    echo "Downloading root filesystem tarball..."
    wget -O $ROOTFS_TARBALL $ROOTFS_TARBALL_URL
fi

# Extract the root filesystem tarball
echo "Extracting root filesystem..."
tar -xzf $ROOTFS_TARBALL -C $ROOTFS_DIR

# Generate the initramfs
INITRAMFS_OUTPUT="$DIR/initramfs-mkinitramfs.img"
mkinitramfs -o $INITRAMFS_OUTPUT -d $ROOTFS_DIR

echo "initramfs has been generated using mkinitramfs: $INITRAMFS_OUTPUT"

# Extract the generated initramfs using unmkinitramfs
echo "Extracting generated initramfs using unmkinitramfs..."
mkdir -p $DIR/initramfs_extracted_from_mkinitramfs
unmkinitramfs $INITRAMFS_OUTPUT $DIR/initramfs_extracted_from_mkinitramfs
echo "initramfs has been generated and unpacked to: $DIR/initramfs_extracted_from_mkinitramfs"
