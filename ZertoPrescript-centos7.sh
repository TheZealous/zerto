#!/bin/bash
#Run this script to prep linux servers for Zerto failover to Azure. Run it before the failover
rpm -e --nodeps NetworkManager #trying to remove the NetworkManager

# Add driver
Dracut=/etc/dracut.conf #Dracut variable declare

cp $Dracut /etc/dracut.conf-copy
if grep -q 'add_drivers+=yes' "$File";
then
	echo "Hooray!!It's available"
	cat $Dracut
else
	echo "Oops!!Not available"
	
	echo add_drivers+="\"hv_vmbus hv_netvsc hv_storvsc mptspi"\" >> $Dracut
	
	cat $Dracut
fi

#Rebuild Dracut
dracut -f -v

#Check to see if the driver got installed.
lsinitrd | grep -E 'hv|mptspi'

#edit grub and add the line below

# /etc/default/grub
#GRUB_CMDLINE_LINUX="console=tty0 rootdelay=300 console=ttyS0 earlyprintk=ttyS0"

grub=/etc/default/grub # Declare variable

#add GRUB_CMDLINE_LINUX="console=tty0 rootdelay=300 console=ttyS0 earlyprintk=ttyS0"
sed -i 'GRUB_CMDLINE_LINUX=/d' "$menu_1st"
echo GRUB_CMDLINE_LINUX="\"console=tty0 rootdelay=300 console=ttyS0 earlyprintk=ttyS0"\" >> "$grub"


#run this command to comit grub
grub2-mkconfig -o /boot/grub2/grub.cfg