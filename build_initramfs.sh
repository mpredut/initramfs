#!/bin/bash

# Definirea directorului INITRAMFS
INITRAMFS_DIR="initramfs"

# Crearea structurii de directoare
mkdir -p "$INITRAMFS_DIR"/{sbin,etc,mnt,proc,run,sys,usr/{bin,sbin,lib64,lib/x86_64-linux-gnu},var}

# Copierea fișierului init din directorul curent în $INITRAMFS_DIR
cp -v ./init $INITRAMFS_DIR

cd $INITRAMFS_DIR
# Create symbolic links
ln -s usr/bin bin
ln -s usr/lib lib
ln -s usr/lib64 lib64
cd ..

# Funcția pentru copierea bibliotecilor necesare unui binar
copy_libs() {
    local binary=$1
    local libs=$(ldd $binary | grep "=>" | awk '{print $3}')
    for lib in $libs; do
        dest_dir=$INITRAMFS_DIR$(dirname $lib)
        mkdir -p $dest_dir
        cp -v $lib $dest_dir
    done
}

# Lista cu binare (busybox, gpart și mkfs)
BINARIES=($(which busybox) $(which gpart) $(which mkfs))

for bin in "${BINARIES[@]}"; do
    copy_libs $bin
    cp -v $bin $INITRAMFS_DIR$bin
done

echo "Structura de directoare și fișierele necesare au fost copiate cu succes."

#aici tb modificat
cp -v $(find /usr/lib -name libc.so.6) "$INITRAMFS_DIR/usr/lib/x86_64-linux-gnu/"
cp -v $(find /usr/lib -name ld-2.31.so) "$INITRAMFS_DIR/usr/lib/x86_64-linux-gnu/"
cp -v $(find /usr/lib -name ld-2.31.so) "$INITRAMFS_DIR/lib/x86_64-linux-gnu/"
cp -v $(find /usr/lib64 -name ld-linux-x86-64.so.2) "$INITRAMFS_DIR/usr/lib64/"
cp -v $(find /usr/lib64 -name ld-linux-x86-64.so.2) "$INITRAMFS_DIR/lib64/"


# Crearea de linkuri simbolice pentru comenzi BusyBox
cd "$INITRAMFS_DIR/bin" || exit 1
echo "Creating symbolic links for BusyBox commands..."
ln -s busybox sh
ln -s busybox echo
ln -s busybox ls
ln -s busybox mount
ln -s busybox switch_root
cd ..
#cd "$INITRAMFS_DIR/usr/bin" || exit 1
./busybox --install -s
cd - || exit 1

