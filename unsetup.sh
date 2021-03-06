#set -e

cd /home/sqy/OpenvSwitch-pof

ovs-vsctl del-br br0
ovs-appctl -t ovsdb-server exit
ovs-appctl -t ovs-vswitchd exit

#rmmod openvswitch
killall ovsdb-server
killall ovs-vswitchd
rm /usr/local/etc/openvswitch/conf.db
sleep 2s
umount -t hugetlbfs none /dev/hugepages
sleep 2s

cd  /home/sqy/dpdk-16.07
#./tools/dpdk-devbind.py  --status
#echo "Input the number of unbind DPDK ports (even): (Enter)"
#read n
#echo "Input the str (for example 05:00.0): (Enter and Next One)"
#for((i=0;i<n;i++));do
#    read port[$i]
#done
#for((i=0;i<n;i++));do
#     ./tools/dpdk-devbind.py --bind=igb ${port[$i]}
#done
./tools/dpdk-devbind.py --bind=ixgbe 0000:05:00.1
./tools/dpdk-devbind.py --bind=ixgbe 0000:05:00.0
./tools/dpdk-devbind.py  --status

grep HugePages_ /proc/meminfo
ps -ef|grep ovs
