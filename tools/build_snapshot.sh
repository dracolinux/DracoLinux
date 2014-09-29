#!/bin/sh
CWD=`pwd`
PKG=/tmp/DracoLinux.$$
VERSION=$(cat VERSION)

if [ "$VERSION" == "" ]; then
  VERSION=$(date +%Y%m%d)
fi

rm -rf $PKG
mkdir -p $PKG/DracoLinux-dist-$VERSION $PKG/DracoLinux-build-$VERSION || exit 1

cp -a $CWD/source/* $PKG/DracoLinux-dist-$VERSION/ || exit 1
cp -a $CWD/* $PKG/DracoLinux-build-$VERSION/ || exit 1
cp -a $CWD/iso $PKG/ || exit 1
cp -a $CWD/packages $PKG/iso/draco/ || exit 1

( cd $PKG;
  for svn in $(find . -type d -name ".svn" -maxdepth 100) ; do
    rm -rf $svn
  done
  for git in $(find . -type d -name ".git" -maxdepth 100) ; do
    rm -rf $git
  done
  for work in $(find . -type d -name "work" -maxdepth 100) ; do
    rm -rf $work
  done  
  find . -type f -name "*~" -exec rm {} \;
)

rm -rf $PKG/DracoLinux-build-$VERSION/{packages,source}/* || exit 1
rm $PKG/DracoLinux-build-$VERSION/iso/boot/{vmlinuz,*.img}

chmod 644 -R $PKG
chown root:root -R $PKG

cd $PKG || exit 1
tar cf DracoLinux-dist-$VERSION.tar DracoLinux-dist-$VERSION || exit 1
tar cJf DracoLinux-build-$VERSION.tar.xz DracoLinux-build-$VERSION || exit 1

cd iso || exit 1

$CWD/tools/mkisofs -o ../DracoLinux-install-i486-$VERSION.iso \
-v -f -J -R -D -A \
"DracoLinux.org" -V "DracoLinux.org" -p "DracoLinux.org" -publisher "DracoLinux.org" \
-no-emul-boot -boot-info-table -boot-load-size 4 -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.boot . || exit 1

mkdir -p draco/source || exit 1
cp ../*tar* draco/source || exit 1

$CWD/tools/mkisofs -o ../DracoLinux-i486-$VERSION.iso \
-v -f -J -R -D -A \
"DracoLinux.org" -V "DracoLinux.org" -p "DracoLinux.org" -publisher "DracoLinux.org" \
-no-emul-boot -boot-info-table -boot-load-size 4 -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.boot . || exit 1

rm -r boot draco/packages || exit 1

$CWD/tools/mkisofs -o ../DracoLinux-source-$VERSION.iso \
-v -f -J -R -D -A \
"DracoLinux.org" -V "DracoLinux.org" -p "DracoLinux.org" -publisher "DracoLinux.org" \
. || exit 1

mv $PKG/*.iso $CWD/ || exit 1
rm -rf $PKG

