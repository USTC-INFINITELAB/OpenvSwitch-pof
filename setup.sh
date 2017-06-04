set -e

#安装ovs-dpdk
export DPDK_DIR=/home/sqy/dpdk-16.07
cd $DPDK_DIR
#dpdk configure
export DPDK_TARGET=x86_64-native-linuxapp-gcc
export DPDK_BUILD=$DPDK_DIR/$DPDK_TARGET
#rm -r x86_64-native-linuxapp-gcc
if [ ! -d /home/sqy/dpdk-16.07/x86_64-native-linuxapp-gcc ]
then
make install T=$DPDK_TARGET DESTDIR=install
fi

#make install T=$DPDK_TARGET DESTDIR=install
# For IVSHMEM, Set `export DPDK_TARGET=x86_64-ivshmem-linuxapp-gcc`

cd /home/sqy
export OVS_DIR=/home/sqy/OpenvSwitch-pof
cd $OVS_DIR
# ./boot.sh
#./configure --with-dpdk=$DPDK_BUILD
./configure CFLAGS="-g -O0" --with-dpdk=$DPDK_BUILD
make -j24
make install

echo 'vm.nr_hugepages=2048' > /etc/sysctl.d/hugepages.conf
sysctl -w vm.nr_hugepages=2048
#grep HugePages_ /proc/meminfo   #获取大页信息
if [ ! -d /dev/hugepages ]
then
mkdir /dev/hugepages
fi

mount -t hugetlbfs none /dev/hugepages
#ifconfig eth2 down
#    modprobe vfio-pci
#   sudo /usr/bin/chmod a+x /dev/vfio
#    sudo /usr/bin/chmod 0666 /dev/vfio/*
cd $DPDK_DIR
modprobe uio_pci_generic
#sudo modprobe uio
#insmod $DPDK_BUILD/kmod/igb_uio.ko
#tools/dpdk-devbind.py --status
#echo "Input the number of DPDK ports (even): (Enter)"
#read n
#echo "Input the eth name (for example eth2): (Enter and Next One)"
#for((i=0;i<n;i++));do
#  read port[$i]
#done
#for((i=0;i<n;i++));do
#  sudo ifconfig ${port[$i]} down
#  sudo ./tools/dpdk-devbind.py --bind=uio_pci_generic ${port[$i]}
#done
./tools/dpdk-devbind.py --bind=uio_pci_generic 0000:05:00.1
./tools/dpdk-devbind.py --bind=uio_pci_generic 0000:05:00.0
./tools/dpdk-devbind.py --status
echo "DPDK Environment Success"
cd $OVS_DIR

mkdir -p /usr/local/etc/openvswitch
mkdir -p /usr/local/var/run/openvswitch
#rm /usr/local/etc/openvswitch/conf.db
ovsdb-tool create /usr/local/etc/openvswitch/conf.db  \
            /usr/local/share/openvswitch/vswitch.ovsschema
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
         --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
         --pidfile --detach
#     ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
#         --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
#         --private-key=db:Open_vSwitch,SSL,private_key \
#         --certificate=Open_vSwitch,SSL,certificate \
#         --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert --pidfile --detach
ovs-vsctl --no-wait init
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
sleep 1s
ovs-vswitchd unix:$DB_SOCK --pidfile --detach
#     ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,0"
#     ovs-vswitchd unix:$DB_SOCK --pidfile --detach
#     ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=6
ovs-appctl vlog/set ANY:ANY:INFO
ovs-appctl vlog/set ofproto:ANY:dbg
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev

ovs-vsctl set-controller br0 tcp:192.168.109.207:6633
ovs-vsctl add-port br0 dpdk0 -- set Interface dpdk0 type=dpdk
ovs-vsctl add-port br0 dpdk1 -- set Interface dpdk1 type=dpdk
#ovs-ofctl show br0
sleep 1s
#ovs-appctl -t ovs-vswitchd exit
#ovs-vswitchd --pidfile
