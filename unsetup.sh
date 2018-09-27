#set -e

cd /home/tsf/OpenvSwitch-pof


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
cd  /home/tsf/dpdk-16.07
#./tools/dpdk-devbind.py --bind=i40e 0000:05:00.0
#./tools/dpdk-devbind.py --bind=i40e 0000:05:00.1

./tools/dpdk-devbind.py --bind=igb 0000:07:00.0
./tools/dpdk-devbind.py --bind=igb 0000:07:00.1

sleep 1s
umount -t hugetlbfs none /dev/hugepages
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
sleep 1s
#./tools/dpdk-devbind.py --bind=i40e 0000:05:00.3
#./tools/dpdk-devbind.py --bind=i40e 0000:05:00.0
./tools/dpdk-devbind.py  --status

grep HugePages_ /proc/meminfo
ps -ef|grep ovs
