
# Linux kernel URL location and name
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.1.tar.xz"
KERNEL_TAR="linux-5.10.1.tar.xz"

# Check if a parameter was passed
if [[ -z "$1" ]]; then
    echo "Usage: $0 <KERNEL_DIR> $1"
    exit 1
fi

KERNEL_DIR="$1"

# Check if we have wget and tar
if ! command -v wget &> /dev/null; then
    echo "wget could not be found. Please install."
    exit 1
fi
if ! command -v tar &> /dev/null; then
    echo "tar could not be found. Please install."
    exit 1
fi

# Download and extract the Linux kernel source
if [[ ! -d "$KERNEL_DIR" ]]; then
    echo "Downloading Linux kernel source..."
    wget $KERNEL_URL
	mkdir -p "$KERNEL_DIR"
    tar -xf $KERNEL_TAR -C "$KERNEL_DIR" --strip-components=1
fi



echo "Adding 'DEBUG: hello world' message to the kernel code..."
modification_successful=false
# Check if we have write permissions on the file
if [[ -w "$KERNEL_DIR/init/main.c" ]]; then
    # Check if the message is already present in the kernel code and if not, add it
    if ! grep -q 'printk(KERN_INFO "DEBUG: hello world\\n");' "$KERNEL_DIR/init/main.c"; then
        sed -i '/kernel_init_freeable();/a\    printk(KERN_INFO "DEBUG: hello world\\n");' "$KERNEL_DIR/init/main.c"

        # Verify if the sed command succeeded
        if grep -q 'printk(KERN_INFO "DEBUG: hello world\\n");' "$KERNEL_DIR/init/main.c"; then
            echo "'DEBUG: hello world' message successfully added to the kernel code."
			modification_successful=true
        else
            echo "Failed to add 'DEBUG: hello world' message to the kernel code."
        fi
    else
        echo "'DEBUG: hello world' message is already present in the kernel code."
    fi
else
    echo "You do not have write permissions to modify $KERNEL_DIR/init/main.c. Please check your permissions."
fi


if $modification_successful; then
    echo "Configuring and building the kernel..."
    cd "$KERNEL_DIR"
    make defconfig
    make -j$(nproc)
	cd ..
else
    echo "Skipping kernel compilation!"
fi

exit 0