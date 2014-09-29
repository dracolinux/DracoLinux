#!/bin/sh
CWD=$(pwd)
PKGS="
autoconf
automake
bin86
bison
diffutils
flex
gettext
groff
m4
make
nasm
oprofile
patch
pcre
perl
pkg-config
texinfo
mk
bmake
"

for i in $PKGS; do
  cd draco/$i || exit 1
  sh ../../tools/bump_build.sh || exit 1
  sh ../../build.sh install || exit 1
  cd $CWD || exit 1
done

