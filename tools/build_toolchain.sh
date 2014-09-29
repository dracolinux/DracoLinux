#!/bin/sh
CWD=$(pwd)
PKGS="glibc binutils gmp mpfr mpc gcc binutils gmp mpfr mpc glibc gcc"
for i in $PKGS; do
  cd draco/$i || exit 1
  sh ../../tools/bump_build.sh || exit 1
  sh ../../build.sh install || exit 1
  cd $CWD || exit 1
done

