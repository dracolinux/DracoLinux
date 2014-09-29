#!/bin/sh
CWD=$(pwd)
CORE="ncurses readline zlib "
PKGS=${CORE}$(ls draco/*|sed '/:/!d;s#draco/##g;s/://g')
for i in $PKGS; do
  if [ -d draco/$i ]; then
    cd draco/$i || exit 1
    sh ../../tools/bump_build.sh || exit 1
    sh ../../build.sh install || exit 1
  fi
  cd $CWD || exit 1
done
