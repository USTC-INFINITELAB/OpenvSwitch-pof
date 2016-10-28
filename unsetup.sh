#set -e
ovs-vsctl del-br br0
ovs-appctl -t ovsdb-server exit
ovs-appctl -t ovs-vswitchd exit

#rmmod openvswitch
#killall ovsdb-server
#killall ovs-vswitchd
rm /usr/local/etc/openvswitch/conf.db
sleep 2s
umount -t hugetlbfs none /dev/hugepages
sleep 1s
grep HugePages_ /proc/meminfo
ps -ef|grep ovs
