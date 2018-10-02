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

# /boot/grub/menu.lst
#GRUB_CMDLINE_LINUX="console=tty0 rootdelay=300 console=ttyS0 earlyprintk=ttyS0"

menu_1st=/boot/grub/menu.lst # Declare variable

#add GRUB_CMDLINE_LINUX="console=tty0 rootdelay=300 console=ttyS0 earlyprintk=ttyS0"

# sed -i 's/kernel.*/& console=tty0 rootdelay=300 console=ttyS0 earlyprintk=ttyS0/'  /boot/grub/menu.lst

#sed -i 's/kernel.*/& console=ttyS0 earlyprintk=ttyS0 rootdelay=300/'  /etc/grub.conf

sed -i 's/ rhgb quiet//g'/boot/grub/grub.conf
sed -i '/kernel/ s/$/ console=ttyS0 earlyprintk=ttyS0 rootdelay=300/' /boot/grub/grub.conf

#Remove persistent network rules
sudo ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
chkconfig network on


echo "Installation is now completed"
