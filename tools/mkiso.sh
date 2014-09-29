#!/bin/sh
VERSION=$(cat ../VERSION)
MKISOFS=../tools/mkisofs
$MKISOFS -o ../DracoLinux-i486-$VERSION.iso \
-v -f -J -R -D -A \
"${NAME}" -V "DracoLinux.org" -p "DracoLinux.org" -publisher "DracoLinux.org" \
-no-emul-boot -boot-info-table -boot-load-size 4 -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.boot .
