#!/bin/sh
LOGS_FOLDER=/etc/reip/
INSTALLATION_LOG=/tmp/reip/install.log
HANDLER_NAME='reiphandler.sh'
REIP_HANDLER_PATH=$LOGS_FOLDER$HANDLER_NAME
CONF_FILE_PATH=$LOGS_FOLDER$CONF_FILE_NAME

mkdir $LOGS_FOLDER

echo $(date -u) "Copying handler file to it's permanent location">>$INSTALLATION_LOG
cp ./reiphandler.sh $REIP_HANDLER_PATH

echo $(date -u) "Copying/Installing Handler">>$INSTALLATION_LOG
cp ./reiphandler.sh /etc/init.d/reiphandler

echo $(date -u) "Granting service execution permissions">>$INSTALLATION_LOG
chmod +x /etc/init.d/reiphandler

echo $(date -u) "Adding service to startup sequence">>$INSTALLATION_LOG
chkconfig --add reiphandler

echo $(date -u) "Adding handler to startup sequence">>$INSTALLATION_LOG


echo $(date -u) "Generating service log file path">>$INSTALLATION_LOG
sed -i -e "s|-target-folder-|$LOGS_FOLDER|" $REIP_HANDLER_PATH

VERSION=$(rpm -q --queryformat '%{VERSION}' $(rpm -qa '(redhat|sl|slf|centos|oraclelinux)-release(|-server|-workstation|-client|-computenode)'))
echo $(date -u) "Resolved OS version is:"$VERSION>>$INSTALLATION_LOG

# Detected Centos/RH7 so set this up with systemd
if  [[ $VERSION == 7* ]] ;
    then
	echo $(date -u) "Detected we're on CentOS/RH 7+">>$INSTALLATION_LOG
        echo $(date -u) "Copying .service unit file to target folder">>$INSTALLATION_LOG

        cp ./reiphandler.service /etc/systemd/system/

        echo $(date -u) "Adding service to startup sequence for CentOS/RHEL 7+">>$INSTALLATION_LOG
        systemctl enable reiphandler
	systemctl start reiphandler
# The OS is not CentOS/RHEL 7+ so fallback to SYSV
else
	echo $(date -u) "Detected we're on something other than CentOS/RH 7+ so assuming SYSV">>$INSTALLATION_LOG
        echo $(date -u) "Starting service">>$INSTALLATION_LOG
        service reiphandler start
fi


echo "Installation Complete. Output sent to install.log"
