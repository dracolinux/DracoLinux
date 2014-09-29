ORIG=$(cat Build|sed '/DRACOSRC_PKG_BUILD/!d;s/DRACOSRC_PKG_BUILD=//')
NEW=$(echo $ORIG+1|bc)
if [ "$NEW" -gt "$ORIG" ]; then
  sed -i 's/DRACOSRC_PKG_BUILD='${ORIG}'/DRACOSRC_PKG_BUILD='${NEW}'/' Build
fi
