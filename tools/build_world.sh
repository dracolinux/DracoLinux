#!/bin/sh
sh tools/build_toolchain.sh || exit 1
sh tools/build_libs.sh || exit 1
sh tools/build_dev.sh || exit 1
sh tools/build_core.sh || exit 1
sh tools/build_all.sh || exit 1
