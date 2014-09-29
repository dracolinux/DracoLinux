#!/bin/sh
dd if=/dev/zero of=initrd bs=1M count=15
mke2fs -F -m 0 -b 1024 initrd
tune2fs -c 0 initrd
mount initrd mnt -o loop
tar xvfJ framework.tar.xz -C mnt || exit 1
cp -av etc/* mnt/etc/
cp -av setupfiles/* mnt/usr/lib/setup/
chmod +x mnt/usr/lib/setup/*
umount mnt
mv initrd setup
gzip setup
mv setup.gz setup.img

