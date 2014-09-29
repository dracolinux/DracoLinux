#!/bin/bash
# Skript to rescan SCSI bus, using the 
# scsi add-single-device mechanism
# (w) 1998-03-19 Kurt Garloff <kurt@garloff.de> (c) GNU GPL
# (w) 2003-07-16 Kurt Garloff <garloff@suse.de> (c) GNU GPL
# $Id: rescan-scsi-bus.sh,v 1.24 2006/07/29 12:34:11 garloff Exp $

setcolor ()
{
  red="\e[0;31m"
  green="\e[0;32m"
  yellow="\e[0;33m"
  bold="\e[0;1m"
  norm="\e[0;0m"
}

unsetcolor () 
{
  red=""; green=""
  yellow=""; norm=""
}

# Return hosts. sysfs must be mounted
findhosts_26 ()
{
  hosts=
  if ! ls /sys/class/scsi_host/host* >/dev/null 2>&1; then
    echo "No SCSI host adapters found in sysfs"
    exit 1;
    #hosts=" 0"
    #return
  fi 
  for hostdir in /sys/class/scsi_host/host*; do
    hostno=${hostdir#/sys/class/scsi_host/host}
    hostname=`cat $hostdir/proc_name`
    hosts="$hosts $hostno"
    echo "Host adapter $hostno ($hostname) found."
  done  
}

# Return hosts. /proc/scsi/HOSTADAPTER/? must exist
findhosts ()
{
  hosts=
  for driverdir in /proc/scsi/*; do
    driver=${driverdir#/proc/scsi/}
    if test $driver = scsi -o $driver = sg -o $driver = dummy -o $driver = device_info; then continue; fi
    for hostdir in $driverdir/*; do
      name=${hostdir#/proc/scsi/*/}
      if test $name = add_map -o $name = map -o $name = mod_parm; then continue; fi
      num=$name
      driverinfo=$driver
      if test -r $hostdir/status; then
	num=$(printf '%d\n' `sed -n 's/SCSI host number://p' $hostdir/status`)
	driverinfo="$driver:$name"
      fi
      hosts="$hosts $num"
      echo "Host adapter $num ($driverinfo) found."
    done
  done
}

# Get /proc/scsi/scsi info for device $host:$channel:$id:$lun
# Optional parameter: Number of lines after first (default = 2), 
# result in SCSISTR, return code 1 means empty.
procscsiscsi ()
{  
  if test -z "$1"; then LN=2; else LN=$1; fi
  CHANNEL=`printf "%02i" $channel`
  ID=`printf "%02i" $id`
  LUN=`printf "%02i" $lun`
  if [ -d /sys/class/scsi_device ]; then
      SCSIPATH="/sys/class/scsi_device/${host}:${channel}:${id}:${lun}"
      if [ -d  "$SCSIPATH" ] ; then
	  SCSISTR="Host: scsi${host} Channel: $CHANNEL Id: $ID Lun: $LUN"
	  if [ "$LN" -gt 0 ] ; then
	      IVEND=$(cat ${SCSIPATH}/device/vendor)
	      IPROD=$(cat ${SCSIPATH}/device/model)
	      IPREV=$(cat ${SCSIPATH}/device/rev)
	      SCSIDEV=$(printf '  Vendor: %-08s Model: %-16s Rev: %-4s' "$IVEND" "$IPROD" "$IPREV")
	      SCSISTR="$SCSISTR
$SCSIDEV"
	  fi
	  if [ "$LN" -gt 1 ] ; then
	      ILVL=$(cat ${SCSIPATH}/device/scsi_level)
	      type=$(cat ${SCSIPATH}/device/type)
	      case "$type" in
		  0) ITYPE="Direct-Access    " ;;
		  1) ITYPE="Sequential-Access" ;;
		  2) ITYPE="Printer          " ;;
		  3) ITYPE="Processor        " ;;
		  4) ITYPE="WORM             " ;;
		  5) ITYPE="CD-ROM           " ;;
		  6) ITYPE="Scanner          " ;;
		  7) ITYPE="Optical Device   " ;;
		  8) ITYPE="Medium Changer   " ;;
		  9) ITYPE="Communications   " ;;
		  10) ITYPE="Unknown          " ;;
		  11) ITYPE="Unknown          " ;;
		  12) ITYPE="RAID             " ;;
		  13) ITYPE="Enclosure        " ;;
		  14) ITYPE="Direct-Access-RBC" ;;
		  *) ITYPE="Unknown          " ;;
	      esac
	      SCSITMP=$(printf '  Type:   %-16s                ANSI SCSI revision: %02d' "$ITYPE" "$((ILVL - 1))")
	      SCSISTR="$SCSISTR
$SCSITMP"
	  fi
	      
      else
	  return 1
      fi
  else
      grepstr="scsi$host Channel: $CHANNEL Id: $ID Lun: $LUN"
      SCSISTR=`cat /proc/scsi/scsi | grep -A$LN -e"$grepstr"`
  fi
  if test -z "$SCSISTR"; then return 1; else return 0; fi
}

# Find sg device with 2.6 sysfs support
sgdevice26 ()
{
  if test -e /sys/class/scsi_device/$host\:$channel\:$id\:$lun/device/generic; then	
    SGDEV=`readlink /sys/class/scsi_device/$host\:$channel\:$id\:$lun/device/generic`
    SGDEV=`basename $SGDEV`
  else
    for SGDEV in /sys/class/scsi_generic/sg*; do
      DEV=`readlink $SGDEV/device`
      if test "${DEV##*/}" = "$host:$channel:$id:$lun"; then
	SGDEV=`basename $SGDEV`; return
      fi
    done
    SGDEV=""
  fi  
}

# Find sg device with 2.4 report-devs extensions
sgdevice24 ()
{
  if procscsiscsi 3; then
    SGDEV=`echo "$SCSISTR" | grep 'Attached drivers:' | sed 's/^ *Attached drivers: \(sg[0-9]*\).*/\1/'`
  fi
}

# Find sg device that belongs to SCSI device $host $channel $id $lun
sgdevice ()
{
  SGDEV=
  if test -d /sys/class/scsi_device; then
    sgdevice26
  else  
    DRV=`grep 'Attached drivers:' /proc/scsi/scsi 2>/dev/null`
    repdevstat=$((1-$?))
    if [ $repdevstat = 0 ]; then
      echo "scsi report-devs 1" >/proc/scsi/scsi
      DRV=`grep 'Attached drivers:' /proc/scsi/scsi 2>/dev/null`
      if [ $? = 1 ]; then return; fi
    fi
    if ! `echo $DRV | grep 'drivers: sg' >/dev/null`; then
      modprobe sg
    fi
    sgdevice24
    if [ $repdevstat = 0 ]; then
      echo "scsi report-devs 0" >/proc/scsi/scsi
    fi
  fi
}       

# Test if SCSI device is still responding to commands
testonline ()
{
  if test ! -x /usr/bin/sg_turs; then return 0; fi
  sgdevice
  if test -z "$SGDEV"; then return 0; fi
  sg_turs /dev/$SGDEV >/dev/null 2>&1
  RC=$?
  #echo -e "\e[A\e[A\e[A${yellow}Test existence of $SGDEV = $RC ${norm} \n\n\n"
  if test $RC = 1; then return $RC; fi
  # OK, device online, compare INQUIRY string
  INQ=`sg_inq -36 /dev/$SGDEV`
  IVEND=`echo "$INQ" | grep 'Vendor identification:' | sed 's/^[^:]*: \(.*\)$/\1/'`
  IPROD=`echo "$INQ" | grep 'Product identification:' | sed 's/^[^:]*: \(.*\)$/\1/'`
  IPREV=`echo "$INQ" | grep 'Product revision level:' | sed 's/^[^:]*: \(.*\)$/\1/'`
  STR=`printf "  Vendor: %-08s Model: %-16s Rev: %-4s" "$IVEND" "$IPROD" "$IPREV"`
  procscsiscsi
  SCSISTR=`echo "$SCSISTR" | grep 'Vendor:'`
  if [ "$SCSISTR" != "$STR" ]; then
    echo -e "\e[A\e[A\e[A\e[A${red}$SGDEV changed: ${bold}\nfrom:${SCSISTR#* } \nto: $STR ${norm}\n\n\n"
    return 1
  fi
  return $RC
}

# Test if SCSI device $host $channen $id $lun exists
# Outputs description from /proc/scsi/scsi, returns SCSISTR 
testexist ()
{
  SCSISTR=
  if procscsiscsi; then
    echo "$SCSISTR" | head -n1
    echo "$SCSISTR" | tail -n2 | pr -o4 -l1
  fi
}

# Perform search (scan $host)
dosearch ()
{
  for channel in $channelsearch; do
    for id in $idsearch; do
      for lun in $lunsearch; do
        SCSISTR=
	devnr="$host $channel $id $lun"
	echo "Scanning for device $devnr ..."
	printf "${yellow}OLD: $norm"
	testexist
	if test ! -z "$remove" -a ! -z "$SCSISTR"; then
	  # Device exists: Test whether it's still online
	  # (testonline returns 1 if it's gone or has changed)
	  testonline
	  if test $? = 1 -o ! -z "$forceremove"; then
	    echo -en "\r\e[A\e[A\e[A${red}REM: "
	    echo "$SCSISTR" | head -n1
	    echo -e "${norm}\e[B\e[B"
	    if test -e /sys/class/scsi_device/${host}:${channel}:${id}:${lun}/device; then
	      echo 1 > /sys/class/scsi_device/${host}:${channel}:${id}:${lun}/device/delete
	      # Try readding, should fail if device is gone
	      echo "$channel $id $lun" > /sys/class/scsi_host/host${host}/scan
	    else
	      echo "scsi remove-single-device $devnr" > /proc/scsi/scsi
	      # Try readding, should fail if device is gone
	      echo "scsi add-single-device $devnr" > /proc/scsi/scsi
	    fi
          fi
	  printf "\r\x1b[A\x1b[A\x1b[A${yellow}OLD: $norm"
	  testexist
	  if test -z "$SCSISTR"; then
	    printf "\r${red}DEL: $norm\r\n\n\n\n"
	    let rmvd+=1;
          fi
	fi
	if test -z "$SCSISTR"; then
	  # Device does not exist, try to add
	  printf "\r${green}NEW: $norm"
	  if test -e /sys/class/scsi_host/host${host}/scan; then
	    echo "$channel $id $lun" > /sys/class/scsi_host/host${host}/scan 2> /dev/null
	  else
	    echo "scsi add-single-device $devnr" > /proc/scsi/scsi
	  fi
	  testexist
	  if test -z "$SCSISTR"; then
	    # Device not present
	    printf "\r\x1b[A";
  	    # Optimization: if lun==0, stop here (only if in non-remove mode)
	    if test $lun = 0 -a -z "$remove" -a $optscan = 1; then 
	      break;
	    fi  
	  else 
	    let found+=1; 
	  fi
	fi
      done
    done
  done
}
 
# main
if test @$1 = @--help -o @$1 = @-h -o @$1 = @-?; then
    echo "Usage: rescan-scsi-bus.sh [options] [host [host ...]]"
    echo "Options:"
    echo " -l      activates scanning for LUNs 0-7    [default: 0]"
    echo " -L NUM  activates scanning for LUNs 0--NUM [default: 0]"
    echo " -w      scan for target device IDs 0 .. 15 [default: 0-7]"
    echo " -c      enables scanning of channels 0 1   [default: 0]"
    echo " -r      enables removing of devices        [default: disabled]"
    echo "--remove:        same as -r"
    echo "--forceremove:   Remove and readd every device (DANGEROUS)"
    echo "--nooptscan:     don't stop looking for LUNs is 0 is not found"
    echo "--color:         use coloured prefixes OLD/NEW/DEL"
    echo "--hosts=LIST:    Scan only host(s) in LIST"
    echo "--channels=LIST: Scan only channel(s) in LIST"
    echo "--ids=LIST:      Scan only target ID(s) in LIST"
    echo "--luns=LIST:     Scan only lun(s) in LIST"  
    echo " Host numbers may thus be specified either directly on cmd line (deprecated) or"
    echo " or with the --hosts=LIST parameter (recommended)."
    echo "LIST: A[-B][,C[-D]]... is a comma separated list of single values and ranges"
    echo " (No spaces allowed.)"
    exit 0
fi

expandlist ()
{
    list=$1
    result=""
    first=${list%%,*}
    rest=${list#*,}
    while test ! -z "$first"; do 
	beg=${first%%-*};
	if test "$beg" = "$first"; then
	    result="$result $beg";
    	else
    	    end=${first#*-}
	    result="$result `seq $beg $end`"
	fi
	test "$rest" = "$first" && rest=""
	first=${rest%%,*}
	rest=${rest#*,}
    done
    echo $result
}

if test ! -d /proc/scsi/; then
  echo "Error: SCSI subsystem not active"
  exit 1
fi	

# Make sure sg is there
modprobe sg >/dev/null 2>&1

# defaults
unsetcolor
lunsearch="0"
idsearch=`seq 0 7`
channelsearch="0"
remove=
forceremove=
optscan=1
if test -d /sys/class/scsi_host; then 
  findhosts_26
else  
  findhosts
fi  

# Scan options
opt="$1"
while test ! -z "$opt" -a -z "${opt##-*}"; do
  opt=${opt#-}
  case "$opt" in
    l) lunsearch=`seq 0 7` ;;
    L) lunsearch=`seq 0 $2`; shift ;;
    w) idsearch=`seq 0 15` ;;
    c) channelsearch="0 1" ;;
    r) remove=1 ;;
    -remove)      remove=1 ;;
    -forceremove) remove=1; forceremove=1 ;;
    -hosts=*)     arg=${opt#-hosts=};   hosts=`expandlist $arg` ;;
    -channels=*)  arg=${opt#-channels=};channelsearch=`expandlist $arg` ;; 
    -ids=*)   arg=${opt#-ids=};         idsearch=`expandlist $arg` ;; 
    -luns=*)  arg=${opt#-luns=};        lunsearch=`expandlist $arg` ;; 
    -color) setcolor ;;
    -nooptscan) optscan=0 ;;
    *) echo "Unknown option -$opt !" ;;
  esac
  shift
  opt="$1"
done    

# Hosts given ?
if test "@$1" != "@"; then 
  hosts=$*; 
fi

echo "Scanning hosts $hosts channels $channelsearch for "
echo " SCSI target IDs " $idsearch ", LUNs " $lunsearch
test -z "$remove" || echo " and remove devices that have disappeared"
declare -i found=0
declare -i rmvd=0
for host in $hosts; do 
  # YOU MAY NEED TO UNCOMMENT THESE TO ALLOW FOR A RESCAN
  #test -e /sys/class/fc_host/host$host/issue_lip && echo 1 > /sys/class/fc_host/host$host/issue_lip 2> /dev/null;
  #echo "- - -" > /sys/class/scsi_host/host$host/scan 2> /dev/null;
  dosearch; 
done
echo "$found new device(s) found.               "
echo "$rmvd device(s) removed.                 "

