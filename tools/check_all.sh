#!/bin/sh
CWD=$(pwd)
for i in draco/*; do
    cd $i || exit 1
    sh ../../build.sh check | grep PACKAGE
  cd $CWD || exit 1
done
