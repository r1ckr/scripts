#!/bin/bash

#Usage: check for mounted drives on $DRIVES_DIR and share them all
#Place the script in /opt/scripts/share-drives.sh
#Add the following line to crontab to check every minute:
# * * * * * /opt/scripts/share-drives.sh 2>&1 | /usr/bin/logger -t drive-sharer

DRIVES_DIR=/media/
AFP_CONFIG_DIR=/usr/local/etc/
AFP_CONFIG_FILE=afp-shares.conf

echo Sharing all drives...

function reload_netatalk {
	echo "Reloading Netatalk..."
    ps -ef | grep afpd | grep -v grep | grep root | awk '{print $3}' | xargs kill -SIGHUP
    echo "Netatalk reloaded"
}

for dir in $DRIVES_DIR*/; do
  drive_name=`echo $dir | awk -F '/' '{print $3}'`
  echo "Adding drive $dir"
  echo "[$drive_name]" >> $AFP_CONFIG_DIR$AFP_CONFIG_FILE.new
  echo "path = '$dir'" >> $AFP_CONFIG_DIR$AFP_CONFIG_FILE.new
  echo "" >> $AFP_CONFIG_DIR$AFP_CONFIG_FILE.new
done

if [ ! -f $AFP_CONFIG_DIR$AFP_CONFIG_FILE ]; then
  echo "Config file doesn't exist, creating new"
  mv $AFP_CONFIG_DIR$AFP_CONFIG_FILE.new $AFP_CONFIG_DIR$AFP_CONFIG_FILE
  reload_netatalk
else
  echo "Comparing result with current config..."
  diff_result=`diff $AFP_CONFIG_DIR$AFP_CONFIG_FILE.new $AFP_CONFIG_DIR$AFP_CONFIG_FILE`
  if [ -z "$diff_result" ]; then
    echo "Configs are the same, ignoring new config..."
    rm -f $AFP_CONFIG_DIR$AFP_CONFIG_FILE.new
    exit 0
  else
    echo "Config has changed, overriding it..."
    mv $AFP_CONFIG_DIR$AFP_CONFIG_FILE.new $AFP_CONFIG_DIR$AFP_CONFIG_FILE
    reload_netatalk
  fi
fi

echo Drives shared!
