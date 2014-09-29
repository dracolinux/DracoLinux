#!/bin/sh
CWD=$(pwd)
PKGS=$(sh check_all.sh|grep SYNC|awk '{print $2}')
for i in $PKGS; do
  if [ -d system/$i ]; then
    cd system/$i || exit 1
    sh ../../build.sh install || exit 1
  fi
  cd $CWD || exit 1
done
