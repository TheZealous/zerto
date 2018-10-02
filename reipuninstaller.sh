#!/bin/bash

UNINSTALL_LOG=/tmp/reip/uninstall.log

echo $(touch /tmp/reip/uninstall.log)

echo $(date -u) 'Stopping service'>>$UNINSTALL_LOG
service reiphandler stop
echo $(date -u) 'Removing service source'>>$UNINSTALL_LOG
rm -rf /etc/reip/
echo $(date -u) 'Removing unit file'>>$UNINSTALL_LOG
rm -rf /etc/systemd/system/reiphandler.service
echo $(date -u) 'Removing service backup'>>$UNINSTALL_LOG
rm -rf reip_handler.sh
echo $(date -u) 'Removing service installer'>>$UNINSTALL_LOG
rm -rf installer.sh
echo $(date -u) 'Removing service service'>>$UNINSTALL_LOG
rm -rf /etc/init.d/reiphandler
echo $(date -u) 'Success'>>$UNINSTALL_LOG
echo "Uninstall complete. Output sent to uninstall.log"
