#!/bin/sh
CWD="../../../tools"
  echo -n "Generating package list ... "
  rm -f CHECKSUMS.md5
  rm -f CHECKSUMS.md5.gz
  rm -f FILELIST.TXT
  #rm -f MANIFEST.bz2
  rm -f PACKAGES.TXT
  rm -f PACKAGES.TXT.gz
  #sh ${CWD}/supportfiles all
  sh ${CWD}/supportfiles PACKAGESTXT
  sh ${CWD}/supportfiles MANIFEST
  sh ${CWD}/supportfiles MD5
  sh ${CWD}/supportfiles FILESTXT
  sh ${CWD}/supportfiles MD5
  rm -f *.meta
  rm -f *.man
  echo "done"
