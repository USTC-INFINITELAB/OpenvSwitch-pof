#set -e

cd ~/OpenvSwitch-pof/


#ovs-vsctl del-br br0
ovs-appctl -t ovs-vswitchd exit
ovs-appctl -t ovsdb-server exit

#rmmod openvswitch
sleep 2s
killall ovsdb-server
killall ovs-vswitchd
rm /usr/local/etc/openvswitch/conf.db
ps -ef|grep ovs

sleep 1s
cd  ~/dpdk-16.07

echo "Unbind dpdk drivers and bind drivers back to original ..."
./tools/dpdk-devbind.py --bind=igb 0000:07:00.0
./tools/dpdk-devbind.py --bind=igb 0000:07:00.1

sleep 1s
grep HugePages_ /proc/meminfo
umount -t hugetlbfs none /dev/hugepages
#sysctl -w vm.nr_hugepages=0        ## clear HugePages config

sleep 1s
./tools/dpdk-devbind.py  --status

grep HugePages_ /proc/meminfo
ps -ef|grep ovs
