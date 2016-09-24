#!/bin/bash

#Usage: check for mounted drives on $DRIVES_DIR and share them all
#Place the script in /opt/scripts/share-drives.sh
#Add the following line to crontab to check every minute:
# * * * * * /opt/scripts/share-drives.sh 2>&1 | /usr/bin/logger -t drive-sharer

DRIVES_DIR=/media/
SMB_CONFIG_DIR=/etc/samba/
SMB_CONFIG_FILE=smb-shares.conf

echo Sharing all drives...

function reload_samba {
	echo "Reloading Samba..."
    smbcontrol smbd reload-config
    echo "Samba reloaded"
}

for dir in $DRIVES_DIR*/; do
  drive_name=`echo $dir | awk -F '/' '{print $3}'`
  echo "Adding drive $dir"
  echo "[Shared $drive_name]" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
  echo "comment = Shared $drive_name" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
  echo "path = \"$dir\"" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
  echo "writeable = Yes" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
  echo "create mask = 0777" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
  echo "directory mask = 0777" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
  echo "browseable = Yes" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
  echo "guest only = Yes" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
  echo "guest ok = Yes" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
  echo "" >> $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
done

if [ ! -f $SMB_CONFIG_DIR$SMB_CONFIG_FILE ]; then
  echo "Config file doesn't exist, creating new"
  mv $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new $SMB_CONFIG_DIR$SMB_CONFIG_FILE
  reload_samba
else
  echo "Comparing result with current config..."
  diff_result=`diff $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new $SMB_CONFIG_DIR$SMB_CONFIG_FILE`
  if [ -z "$diff_result" ]; then
    echo "Configs are the same, ignoring new config..."
    rm -f $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new
    exit 0
  else
    echo "Config has changed, overriding it..."
    mv $SMB_CONFIG_DIR$SMB_CONFIG_FILE.new $SMB_CONFIG_DIR$SMB_CONFIG_FILE
    reload_samba
  fi
fi

echo Drives shared!
