#!/bin/sh
CWD=$(pwd)
PKGS="
syslinux
sysvinit
tar
termcap-compat
texinfo
time
tnftp
traceroute
tree
udev
usbutils
util-linux
which
whois
wireless_tools
wpa_supplicant
xfsdump
xfsprogs
xz
zlib"

for i in $PKGS; do
  cd system/$i || exit 1
  sh ../../build.sh install || exit 1
  cd $CWD || exit 1
done

