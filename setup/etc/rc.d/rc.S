#!/bin/sh
# rc.S:  Basic system initialization.

# remove /etc/mtab* so mount creates the /etc/mtab file
#/bin/rm -f /etc/mtab* /etc/nologin
/bin/rm -f /etc/nologin

# Mounts /proc:
/bin/mount -av -t nonfs

/sbin/swapon -a 2> /dev/null

if [ -x /sbin/ldconfig ]; then
  /sbin/ldconfig -v
fi

# Try to mount sysfs:
if cat /proc/filesystems | grep -w sysfs 1> /dev/null 2> /dev/null ; then
  mount -t sysfs sysfs /sys 2> /dev/null
fi

# System logger (mostly to eat annoying messages):
/sbin/syslogd 2> /dev/null
sleep 1
/sbin/klogd -c 3 1> /dev/null

# Replace some startup binaries with better versions:
( cd /bin
  rm -f grep gzip tar gunzip zcat df
  ln -sf df.bin df
  ln -sf grep.bin grep
  ln -sf gzip.bin gzip
  ln -sf tar-1.13 tar
  ln -sf gzip gunzip
  ln -sf gzip zcat
)

# Make detected partitions:
/dev/makedevs.sh

if [ -x /etc/rc.d/rc.inet1 ]; then
  /bin/sh /etc/rc.d/rc.inet1
fi

# Check /proc/partitions again:
/dev/makedevs.sh

# Don't automatically blank the screen, or it will go black during the install
# process when stray keystrokes might be dangerous:
/bin/setterm -blank 0

clear
cat /etc/motd
