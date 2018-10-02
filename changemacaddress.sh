#!/bin/bash
#
# Copyright (c) 2018 by PROS, Inc.  All Rights Reserved.
# This software is the confidential and proprietary information of
# PROS, Inc. ("Confidential Information").
# You may not disclose such Confidential Information, and may only
# use such Confidential Information in accordance with the terms of
# the license agreement you entered into with PROS.
#
#
# This script will scan the directories asked and will print the following format:
# Path /file name, create date, access date, last modified, size, user.
# 
# Pros IT Server Team.
#


IPADDRESS=`(ifconfig -a | grep Bcast | awk '{print $2}' | cut -f 2 -d :)`
NICDEV=$(route | grep '^default' | grep -o '[^ ]*$')
GETIP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' )
GETIPREMOTE=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
IP=$(hostname --ip-address)
DEVICE=$(ls -la /etc/sysconfig/network-scripts/ | grep ifcfg-* | grep -v ifcfg-lo | awk '{print $9}')
DEVLOC=$(ls -la /etc/sysconfig/network-scripts/ifcfg-* | grep -v ifcfg-lo | awk '{print $9}')
HWADDR=$(cat /etc/sysconfig/network-scripts/ifcfg-$NICDEV | grep HWADDR  | cut -b 9-25 )
DIRDATE=$(date +"%m-%d-%y")
HOST_NAME=$(uname -n)
KERNEL=$(uname -r)
VERSION=$(cat /etc/redhat-release)
OSRELEASE=$(lsb_release -r | awk '{print $2}' | cut -b 1)
OSDESCRIPTION=$(lsb_release -d | cut -b 14-40)
#RULESMACVr6=$(cat  /etc/udev/rules.d/70-persistent-net.rules  | awk '{print $4}' | grep ATTR | cut -b 17-33 | sort -du)
RULESMACVr6=$(cat  /etc/udev/rules.d/70-persistent-net.rules  | awk '{print $4}' | grep ATTR   | sed 's/[/ATTR{address}== " ,]//g' )
RULESLOCVr6=/etc/udev/rules.d/70-persistent-net.rules
CURRENTMACVr6=$(ifconfig -a | grep eth0 | awk '{print $5}')
NEWMACVr7=$(cat  /etc/udev/rules.d/70-persistent-ipoib.rules | grep ACTION  | awk '{print $6}' | cut -b 19-41)
MACADDRESSVr7=$(ip -o link  | awk '{print $2,$(NF-2)}'  | grep $NICDEV | awk '{print $2}')
#GRABMAC=$(cat $DEVLOC | grep HWADDR | cut -b 9-25 ) 
GRABMAC=$(cat $DEVLOC | grep HWADDR | sed 's/[HWADDR= "]//g' ) 
RULESMACVr7=$(cat /etc/udev/rules.d/70-persistent-ipoib.rules | grep ACTION  | awk '{print $6}' | sed 's/[ATTR{address}=="?* " , ]//g' )
RULESLOCVr7=/etc/udev/rules.d/70-persistent-ipoib.rules
clear 
#



echo "  " 
#echo "This system is a: $OSDESCRIPTION"  

echo $OSRELEASE >> /dev/null 
case $OSRELEASE in
		6)
		#GRABMAC=$(cat $DEVLOC | grep HWADDR | cut -b 9-25 ) 
		#RULESMACVr6=$(cat  /etc/udev/rules.d/70-persistent-net.rules  | awk '{print $4}' | grep ATTR | cut -b 17-33 | sort -du)
			echo "This server is at $OSDESCRIPTION" 
			echo " "
			echo "My network device is"		$NICDEV 
			echo "My current ip address is"		$IP
			echo "The current Mac Address from ifconfig command" $CURRENTMACVr6
			echo "The rules MAC addres in" $RULESLOCVr6	$RULESMACVr6  
			echo "The grabbed Mac addrees from $DEVLOC" $GRABMAC
			echo " "  
			
			#echo "CURRENTMACVr6" $CURRENTMACVr6 	#ifconfig -a | grep eth0 | awk '{print $5}' 
			#echo "RULESMACVr6" $RULESMACVr6  
			#echo "GRABMAC " $GRABMAC
			
			
			cat /etc/sysconfig/network-scripts/ifcfg-$NICDEV | grep HWADDR  | cut -b 9-25 >> /dev/null 
			if [ $GRABMAC == $RULESMACVr6 ] 
			then 
				echo " "
				echo "The mac address is the same, no change is needed."
			else
				echo " "
				echo "The mac address are not the same, please wait while we change it."
				echo " "
				cp -p $DEVLOC /tmp/ifcfg-$NICDEV.orig
				sed '/HWADDR/ d' $DEVLOC > /tmp/ifcfg-$NICDEV.NEW
				echo "HWADDR=\"$RULESMACVr6\"" >> /tmp/ifcfg-$NICDEV.NEW
				cp -fp /tmp/ifcfg-$NICDEV.NEW $DEVLOC
				echo "This is the new MAC Address in $DEVLOC" 
				cat /etc/sysconfig/network-scripts/ifcfg-$NICDEV | grep HWADDR
				service network restart
			fi 
			echo " " 
			
			;; 	
		
		7)
		#MACADDRESSVr7=$(ip -o link  | awk '{print $2,$(NF-2)}'  | grep $NICDEV | awk '{print $2}')
		CURRENTNEWMACVr7=$(ifconfig -a $NICDEV  | grep ether | awk '{print $2}')

		
			echo "This server is at $OSDESCRIPTION" 
			echo " "
			echo "My network device is"		$NICDEV 
			echo "My ip address is"		$IP
			echo "The current Mac Address from ifconfig command"		$CURRENTNEWMACVr7
			echo "The rules MAC addres in" $RULESLOCVr7	$RULESMACVr7  
			echo "The grabbed Mac addrees from $DEVLOC" $GRABMAC
			echo " "
			
			cat /etc/udev/rules.d/70-persistent-ipoib.rules | grep ACTION  | awk '{print $6}' | sed 's/[ATTR{address}=="?* " , ]//g'
			if [ $GRABMAC == $RULESMACVr7 ] ; then 
				echo " "
				echo "The mac address is the same, no change is needed."
			else 
				echo " "
				echo "The mac address are not the same, please wait while we change it."
				echo " "
				cp -p $DEVLOC /tmp/ifcfg-$NICDEV.orig
				sed '/HWADDR/ d' $DEVLOC > /tmp/ifcfg-$NICDEV.NEW
				echo "HWADDR=\"$RULESMACVr7\"" >> /tmp/ifcfg-$NICDEV.NEW
				cp -fp /tmp/ifcfg-$NICDEV.NEW $DEVLOC
				echo "This is the new MAC Address in $DEVLOC" 
				cat /etc/sysconfig/network-scripts/ifcfg-$NICDEV | grep HWADDR
			fi 
			
			;;  

esac
sleep 3
