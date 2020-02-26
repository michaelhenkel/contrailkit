#!/bin/sh
function failed {
	printf "Kernel module test suite FAILED\n"
	/sbin/poweroff -f
}

uname -a
modinfo /tmp/vrouter.ko || failed
insmod /tmp/vrouter.ko || failed
[ -n "$(dmesg | grep -o 'vrouter')" ] || failed
#rmmod vrouter || failed
mac=$(cat /sys/class/net/eth0/address)
/usr/bin/vif --create vhost0 --mac $mac
/usr/bin/vif --add eth0 --mac $mac --vrf 0 --vhost-phys --type physical
/usr/bin/vif --add vhost0 --mac $mac --vrf 0 --type vhost --xconnect eth0
ip link set dev vhost0 up
dev_route=$(ip route get 8.8.8.8 |grep "8.8.8.8 via" |awk '{print $3}')
routes=$(ip r sh dev eth0)
eth0_ip=$(ip a sh dev eth0 |grep "inet "|awk '{print $2}')
ip addr del ${eth0_ip} dev eth0
ip addr add ${eth0_ip} dev vhost0
ip route add default via $dev_route
printf "Kernel module test suite PASSED\n"

#/sbin/poweroff -f
