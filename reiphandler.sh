#!/usr/bin/env bash
#reip_handler.sh


# chkconfig: 345 99 10
# description: Script to run a on start up and perform re-ip if needed

LOCKFILE=/var/lock/subsys/reiphandler
PROCESS_LOG_FILE=/etc/reip/reip_handler.log
DMIDECODE_OUTPUT=/etc/reip/dmidecode.log

start(){
    # Touch our lock file so that stopping will work correctly
	touch ${LOCKFILE}
    VERSION=$(rpm -q --queryformat '%{VERSION}' $(rpm -qa '(redhat|sl|slf|centos|oraclelinux)-release(|-server|-workstation|-client|-computenode)'))

    #HV_RESPONSE=$(sudo dmidecode | grep -i -E 'amazon|microsoft')
	HV_RESPONSE=$(dmidecode -s system-manufacturer | grep -i -E 'amazon|microsoft')
    #IS_NM_INSTALLED=$(service NetworkManager status | grep 'active')
	echo $(dmidecode -s system-manufacturer | grep -i -E 'amazon|microsoft') >> $DMIDECODE_OUTPUT
	#get the size of the string based on the dmidecode output
	str_length=${#HV_RESPONSE}

	#if the string is greater than zero then we have a match for amazon or microsoft
    if [ $str_length -gt 0 ];
    # We're in AWS or Azure
	then
    			echo $(date -u) '(Azure) Hypervisor is AWS or Azure' >> $PROCESS_LOG_FILE
			echo $(date -u) '(Azure) Backing up persistent rules (if exist) to /etc/reip/70-persistent-net.rules' >> $PROCESS_LOG_FILE
			cp /etc/udev/rules.d/70-persistent-net.rules /etc/reip/70-persistent-net.rules
			echo $(date -u) '(Azure) Creating fail over toggle file /etc/reip/fail_over' >> $PROCESS_LOG_FILE
			touch /etc/reip/fail_over
			echo $(date -u) '(Azure) Removing (if exist) persistent rules' >> $PROCESS_LOG_FILE
        		rm -f /etc/udev/rules.d/70-persistent-net.rules
			echo $(date -u) '(Azure) Rebuilding persistent rules and renaming NICs' >> $PROCESS_LOG_FILE
        		udevadm trigger --subsystem-match=net
        		sleep 5
        		$(sed -i 's/eth[1-9]/eth0/g' /etc/udev/rules.d/70-persistent-net.rules)
        		udevadm trigger --type=devices --action=add
			sleep 5
        		echo $(date -u) '(Azure) Flushing IP Configuration on eth0' >> $PROCESS_LOG_FILE
        		ip addr flush dev eth0
			sleep 2
        		echo $(date -u) '(Azure) Starting DHCP on eth0' >> $PROCESS_LOG_FILE
        		dhclient eth0
			sleep 10
			rm -f /etc/udev/rules.d/70-persistent-net.rules
			

### This second section covers the DNS update when VM failover to Azure.


currentIP=`ip -o -4 addr show | grep "eth\|ens" | awk -F '[ /]+' '/global/ {print $4}'`
echo "My current IP address is $currentIP"

### uncomment this line to perform the DNS update
/opt/quest/sbin/dnsupdate -rv -s zwusts-ad1.prosrm.com $currentIP
/opt/quest/sbin/dnsupdate -rv -s zwusts-ad2.prosrm.com $currentIP

	else
    		echo $(date -u) "Hypervisor is vCenter. Use static IP config." >> $PROCESS_LOG_FILE
			### This section covers the DNS update when VM failback to on-prem VMware.
currentIP=`ip -o -4 addr show | grep "eth\|ens" | awk -F '[ /]+' '/global/ {print $4}'`
echo "My current IP address is $currentIP"

### uncomment this line to perform the DNS update
/opt/quest/sbin/dnsupdate -rv -s fth-ad01.prosrm.com $currentIP
/opt/quest/sbin/dnsupdate -rv -s fth-ad02.prosrm.com $currentIP
			echo $(date -u) "Running Update to new MAC address in VMware." >> $PROCESS_LOG_FILE 
			sh ./changemacaddress.sh
    fi
    rm -rf ${LOCKFILE}
}

stop(){
# Remove our lock file
rm -rf ${LOCKFILE}
# Run that command that we wanted to run
echo $(date -u)" ReIP handler stopped" >> $PROCESS_LOG_FILE
}

case "$1" in
    start) start;;
    stop) stop;;
    *)
        echo $"Usage: $0 {start|stop}"
        exit 1
esac
exit 0
