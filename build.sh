#!/bin/sh
#
# Build script for DracoLinux
# (c) 2008-2012 Ole Andre Rodlie <olear@dracolinux.org>
#

set +e
OPT=$1
CWD=$(pwd)
DATE="`date +%Y%m%d`"
TAR="/bin/tar"
GET="/bin/ftp"
RUN="."
PATCH="/usr/bin/patch"
AUTOCONF="/usr/bin/autoconf"

DRACOSRC_DIR=$(cd ../../;pwd)
if [ ! -f ${DRACOSRC_DIR}/build.sh ]; then
  echo
  echo "=> Not part of the build tree"
  echo
  exit 1
fi

MAKEPKG="sh ${DRACOSRC_DIR}/common/pkgtools/makepkg"
EXPLODEPKG="sh ${DRACOSRC_DIR}/common/pkgtools/explodepkg"
UPGRADEPKG="sh ${DRACOSRC_DIR}/common/pkgtools/upgradepkg"
REMOVEPKG="sh ${DRACOSRC_DIR}/common/pkgtools/removepkg"

DRACOSRC_ZIP=txz
DRACOSRC_TAG=
DRACOSRC_KERNEL=$(uname -r)
DRACOSRC_PROBE_ARCH=$(uname -m)
DRACOSRC_LOG=/var/log/packages
DRACOSRC_CACHE="${DRACOSRC_DIR}/source"
DRACOSRC_PACKAGES="${DRACOSRC_DIR}/packages"
DRACOSRC_PKG_SRC_DIR=${CWD} 
DRACOSRC_PKG_WORK="${DRACOSRC_PKG_SRC_DIR}/work"
DRACOSRC_PKG="${DRACOSRC_PKG_WORK}/output"
DRACOSRC_FAIL="FAILED (work/log for more info)"

DRACOSRC_PKG_LOG="${DRACOSRC_PKG_WORK}/log"

if [ "${DRACOSRC_PROBE_ARCH}" = "i486" ]; then
  DRACOSRC_ARCH=i486
elif [ "${DRACOSRC_PROBE_ARCH}" = "i586" ]; then
  DRACOSRC_ARCH=i486
elif [ "${DRACOSRC_PROBE_ARCH}" = "i686" ]; then
  DRACOSRC_ARCH=i486
elif [ "${DRACOSRC_PROBE_ARCH}" = "x86_64" ]; then
  DRACOSRC_ARCH=x86_64
fi

if [ ! "${DRACOSRC_ARCH}" ]; then
  echo
  echo "=> CPU not supported"
  echo
  exit 1
else
  echo "=> Building for ${DRACOSRC_ARCH}"
fi

if [ "${DRACOSRC_ARCH}" = "i486" ]; then
  DRACOSRC_FLAGS="-O2 -pipe -march=i486 -mtune=i686"
elif [ "${DRACOSRC_ARCH}" = "x86_64" ]; then
  DRACOSRC_FLAGS="-O2 -fPIC"
fi
     
DRACOSRC_PKG_DIFF_DIR=diff
DRACOSRC_PKG_BUILD_SCRIPT=Build
DRACOSRC_PKG_PATCH_SCRIPT=Patch
DRACOSRC_PKG_PRECONF_SCRIPT=PreConf
DRACOSRC_PKG_CUSTOM_SCRIPT=Custom
DRACOSRC_PKG_MAKE_SCRIPT=Make
DRACOSRC_PKG_EXTRA_SCRIPT=Extra
DRACOSRC_PKG_INSTALL_SCRIPT=Install

if [ ! -f ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_BUILD_SCRIPT} ]; then
  echo
  echo "=> Build file not found"
  echo
  exit 1
fi

echo -n "=> Executing Build file ... "
${RUN} ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_BUILD_SCRIPT} || exit 1
echo "OK"

DRACOSRC_PKG_BUILD=${DRACOSRC_TAG}${DRACOSRC_PKG_BUILD}
echo "=> ${DRACOSRC_PKG_NAME} ${DRACOSRC_PKG_VERSION} ${DRACOSRC_PKG_BUILD}"

if [ "${OPT}" = "deinstall" ]; then
  ${RUN} ${REMOVEPKG} ${DRACOSRC_PKG_NAME}
  exit 1
fi

if [ -d ${DRACOSRC_PKG_WORK} ]; then
  echo -n "=> Removing work directory ... "
  rm -rf ${DRACOSRC_PKG_WORK}
  echo "OK"
else
  mkdir -p ${DRACOSRC_PKG_WORK}
fi  

if [ "${OPT}" = "check" ]; then
  if [ ! -f "${DRACOSRC_LOG}/${DRACOSRC_PKG_NAME}-${DRACOSRC_PKG_VERSION}-${DRACOSRC_ARCH}-${DRACOSRC_PKG_BUILD}" ]; then
    echo "PACKAGE ${DRACOSRC_PKG_NAME} IS OUT OF SYNC, PLEASE REVIEW!"
  fi
  if [ ! -f "$DRACOSRC_PACKAGES/$DRACOSRC_PKG_NAME-$DRACOSRC_PKG_VERSION-$DRACOSRC_ARCH-$DRACOSRC_PKG_BUILD.$DRACOSRC_ZIP" ]; then
    echo "PACKAGE $DRACOSRC_PKG_NAME DOES NOT EXISTS, PLEASE BUILD!"
  fi
  exit 1
fi

if [ ! -d ${DRACOSRC_PKG} ]; then
  mkdir -p ${DRACOSRC_PKG}
fi

echo "* ${DRACOSRC_PKG_NAME} ${DRACOSRC_PKG_VERSION}-${DRACOSRC_PKG_BUILD} build started : "$(date)"" >> $DRACOSRC_PKG_LOG

if [ "${OPT}" != "fetch" ]; then

if [ -f ${DRACOSRC_PKG_SRC_DIR}/Override ]; then
  echo -n "=> Running override ... "
  ${RUN} ${DRACOSRC_PKG_SRC_DIR}/Override 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
  echo "OK"
fi

if [ -f ${DRACOSRC_PKG_SRC_DIR}/framework.tar.gz ]; then
  echo -n "=> Extracting framework ... "
  ( cd $DRACOSRC_PKG ; ${EXPLODEPKG} ${DRACOSRC_PKG_SRC_DIR}/framework.tar.gz 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; } )
  echo "OK"
fi

fi

if [ ! "${DRACOSRC_NOSOURCE}" ]; then

  if [ "${DRACOSRC_PKG_ALT_NAME}" ]; then
    DRACOSRC_PKG_DWN=${DRACOSRC_PKG_ALT_NAME}
  else
    DRACOSRC_PKG_DWN="${DRACOSRC_PKG_NAME}-"
  fi

  if [ "${DRACOSRC_PKG_ALT_VERSION}" ]; then
    DRACOSRC_PKG_DWN_VERSION=${DRACOSRC_PKG_ALT_VERSION}
  else
    DRACOSRC_PKG_DWN_VERSION=${DRACOSRC_PKG_VERSION}
  fi

  DRACOSRC_PKG_SRC_FILE=${DRACOSRC_PKG_DWN}${DRACOSRC_PKG_DWN_VERSION}.tar.xz
  if [ ! -f ${DRACOSRC_CACHE}/${DRACOSRC_PKG_SRC_FILE} ]; then
    echo -n "=> Source not available. "
    exit 1
  fi

  EXTRACT="${TAR} xfJ"
 
  echo -n "=> Extracting source ... "
  ${EXTRACT} ${DRACOSRC_CACHE}/${DRACOSRC_PKG_SRC_FILE} -C ${DRACOSRC_PKG_WORK} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
  echo "OK"

  if [ "${DRACOSRC_PKG_ALT_PKG_SRC}" ]; then
    DRACOSRC_PKG_SRC=${DRACOSRC_PKG_WORK}/${DRACOSRC_PKG_ALT_PKG_SRC}
  else
    DRACOSRC_PKG_SRC=${DRACOSRC_PKG_WORK}/${DRACOSRC_PKG_DWN}${DRACOSRC_PKG_DWN_VERSION}
  fi

  cd ${DRACOSRC_PKG_SRC} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }

  if [ -f ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_PATCH_SCRIPT} ]; then
    echo -n "=> Executing Patch file ... "
    ${RUN} ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_PATCH_SCRIPT} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
    echo "OK"
  fi

  if [ "${DRACOSRC_PKG_ALT_DIFF_PATH}" ]; then
    DRACOSRC_PKG_DIFF_PATH=${DRACOSRC_PKG_ALT_DIFF_PATH}
  else
    DRACOSRC_PKG_DIFF_PATH=${DRACOSRC_PKG_SRC_DIR}
  fi

  if [ -a $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR} ]; then
    echo -n "=> Patching ... "
    if [ -a $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR}/2 ]; then
      for i in `ls $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR}/2`; do
        ${PATCH} -p2 -l < $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR}/2/$i 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
      done   
    fi
    if [ -a $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR}/1 ]; then
      for i in `ls $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR}/1`; do
        ${PATCH} -p1 -l < $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR}/1/$i 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
      done
    fi
    if [ -a $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR}/0 ]; then
      for i in `ls $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR}/0`; do
        ${PATCH} -p0 -l < $DRACOSRC_PKG_DIFF_PATH/${DRACOSRC_PKG_DIFF_DIR}/0/$i 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
      done
    fi
    echo "OK"
  fi

  if [ -f ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_PRECONF_SCRIPT} ]; then
    echo -n "=> Executing PreConf file ... "
    ${RUN} ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_PRECONF_SCRIPT} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
    echo "OK"
  fi

  chown -R root:root .
  find . \
 \( -perm 777 -o -perm 775 -o -perm 711 -o -perm 555 -o -perm 511 \) \
 -exec chmod 755 {} \; -o \
 \( -perm 666 -o -perm 664 -o -perm 600 -o -perm 444 -o -perm 440 -o -perm 400 \) \
 -exec chmod 644 {} \;

  if [ -f ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_CUSTOM_SCRIPT} ]; then
    echo -n "=> Executing Custom file ... "
    ${RUN} ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_CUSTOM_SCRIPT} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
    echo "OK"
  else
    if [ "${DRACOSRC_PKG_USE_AUTOCONF}" ]; then
      echo -n "=> Running autoconf ... "
      ${AUTOCONF} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
      echo "OK"
    fi
    echo -n "=> Configuring source ... "
    CFLAGS="${DRACOSRC_FLAGS}" CXXFLAGS="${DRACOSRC_FLAGS}" ./configure ${DRACOSRC_PKG_CONFIGURE} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
    echo "OK"
    if [ -f ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_MAKE_SCRIPT} ]; then
      echo -n "=> Executing Make file ... "
      ${RUN} ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_MAKE_SCRIPT} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
      echo "OK"
    else
      echo -n "=> Compiling, please wait (tail -f work/log for more info) ... "
      make -j4 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
      echo "OK"
      echo -n "=> Installing ... "
      make install DESTDIR=${DRACOSRC_PKG} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
      echo "OK"
    fi
  fi

fi

if [ -f ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_EXTRA_SCRIPT} ]; then
  echo -n "=> Executing Extra file ... "
  ${RUN} ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_EXTRA_SCRIPT} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
  echo "OK"
fi

if [ ! $DRACOSRC_NOSTRIP ]; then
echo -n "=> Stripping ... "
( cd ${DRACOSRC_PKG} ;
  find . | xargs file | grep "executable" | grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null
  find . | xargs file | grep "shared object" | grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null 
)
echo "OK"
fi

if [ -a $DRACOSRC_PKG/usr/info ]; then
( cd $DRACOSRC_PKG/usr/info ;
  if [ -a dir ]; then
    if [ ! "$DRACOSRC_PKG_NAME" = "texinfo" ]; then
      rm dir
    fi
  fi
  gzip -9 *
  if [ -a dir.gz ]; then
    gunzip dir.gz
  fi
)
fi   

if [ ! "$DRACOSRC_NOMANGZ" ]; then
  if [ -a $DRACOSRC_PKG/usr/man ]; then
    ( cd $DRACOSRC_PKG/usr/man ;
      for manpagedir in $(find . -type d -name "man*") ; do
        ( cd $manpagedir ;
          for eachpage in $( find . -type l -maxdepth 1) ; do
            ln -s $( readlink $eachpage ).gz $eachpage.gz
            rm $eachpage
          done
          gzip -9 *.*
        )
      done
    )
  fi
fi

if [ -a $DRACOSRC_PKG/lib/modules ]; then
  find $DRACOSRC_PKG/lib/modules -type f -name "*.ko" -exec gzip -9f {} \;
fi

( cd $DRACOSRC_PKG;
  for svn in $(find . -type d -name ".svn" -maxdepth 50) ; do
    rm -rf $svn
  done
  find . -type f -name "*~" -exec rm {} \;
)

mkdir -p $DRACOSRC_PKG/usr/doc/$DRACOSRC_PKG_NAME-$DRACOSRC_PKG_VERSION
( cd ${DRACOSRC_PKG_SRC} ; cp -a REL* COPY* AUTH* READ* Change* LIC* $DRACOSRC_PKG/usr/doc/$DRACOSRC_PKG_NAME-$DRACOSRC_PKG_VERSION/ 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} )

mkdir -p $DRACOSRC_PKG/install
cat >$DRACOSRC_PKG/install/slack-desc <<EOF   
$DRACOSRC_PKG_NAME: ${DRACOSRC_PKG_NAME}
$DRACOSRC_PKG_NAME:
$DRACOSRC_PKG_NAME: ${DRACOSRC_PKG_DESC}
$DRACOSRC_PKG_NAME:
$DRACOSRC_PKG_NAME:
$DRACOSRC_PKG_NAME:
$DRACOSRC_PKG_NAME:
$DRACOSRC_PKG_NAME:
$DRACOSRC_PKG_NAME: 
$DRACOSRC_PKG_NAME: 
$DRACOSRC_PKG_NAME:
EOF

if [ -f ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_INSTALL_SCRIPT} ]; then
  cat ${DRACOSRC_PKG_SRC_DIR}/${DRACOSRC_PKG_INSTALL_SCRIPT} > $DRACOSRC_PKG/install/doinst.sh || exit 1
fi

if [ "${DRACOSRC_NOPKG}" ]; then
  exit 1
fi

if [ "${DRACOSRC_PKG_CAT}" ]; then
  DRACOSRC_PACKAGES=${DRACOSRC_PACKAGES}/${DRACOSRC_PKG_CAT}
  if [ ! -d $DRACOSRC_PACKAGES ]; then
    mkdir -p $DRACOSRC_PACKAGES
  fi
fi

DRACOSRC_PKG_TGZ=${DRACOSRC_PACKAGES}/${DRACOSRC_PKG_NAME}-${DRACOSRC_PKG_VERSION}-${DRACOSRC_ARCH}-${DRACOSRC_PKG_BUILD}.${DRACOSRC_ZIP}
( cd $DRACOSRC_PKG ;
  echo -n "=> Creating package ... "
  ${MAKEPKG} -l y -c n ${DRACOSRC_PKG_TGZ} 2>>${DRACOSRC_PKG_LOG} 1>>${DRACOSRC_PKG_LOG} || { echo ${DRACOSRC_FAIL}; exit 1; }
  #tree > $DRACOSRC_PKG_TGZ.manifest
  echo "OK"
)

echo "* Build ended: "$(date)"" >> $DRACOSRC_PKG_LOG
#cat $DRACOSRC_PKG_LOG > $DRACOSRC_PKG_TGZ.build

#( cd $DRACOSRC_PACKAGES;
#  DRACOSRC_PKGFILE=$DRACOSRC_PKG_NAME-$DRACOSRC_PKG_VERSION-$DRACOSRC_ARCH-$DRACOSRC_PKG_BUILD.$DRACOSRC_ZIP
#  md5sum $DRACOSRC_PKGFILE > $DRACOSRC_PKGFILE.md5
#  sha1sum $DRACOSRC_PKGFILE > $DRACOSRC_PKGFILE.sha1
#  xz $DRACOSRC_PKGFILE.manifest
#  xz $DRACOSRC_PKGFILE.build
#)

echo "=> Build done."

if [ "$1" == "install" ]; then
  if [ -f $DRACOSRC_PKG_TGZ ]; then
    ${UPGRADEPKG} --install-new --reinstall $DRACOSRC_PKG_TGZ
  fi
fi
