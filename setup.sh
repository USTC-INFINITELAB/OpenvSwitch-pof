set -e

#安装ovs-dpdk
export DPDK_DIR=/usr/src/dpdk-16.07
cd $DPDK_DIR
#dpdk配置
export DPDK_TARGET=x86_64-native-linuxapp-gcc
export DPDK_BUILD=$DPDK_DIR/$DPDK_TARGET
#rm -r x86_64-native-linuxapp-gcc
#make install T=$DPDK_TARGET DESTDIR=install
# For IVSHMEM, Set `export DPDK_TARGET=x86_64-ivshmem-linuxapp-gcc`

cd /usr/src
export OVS_DIR=/usr/src/OpenvSwitch-pof
cd $OVS_DIR
# ./boot.sh
./configure --with-dpdk=$DPDK_BUILD
make -j24
make install

echo 'vm.nr_hugepages=2048' > /etc/sysctl.d/hugepages.conf
sysctl -w vm.nr_hugepages=2048
#grep HugePages_ /proc/meminfo   #获取大页信息
mount -t hugetlbfs none /dev/hugepages

#    modprobe vfio-pci
#   sudo /usr/bin/chmod a+x /dev/vfio
#    sudo /usr/bin/chmod 0666 /dev/vfio/*
#    $DPDK_DIR/tools/dpdk-devbind.py --bind=vfio-pci eth1
#   $DPDK_DIR/tools/dpdk-devbind.py --status
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
ovs-vswitchd unix:$DB_SOCK --pidfile --detach
#     ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,0"
#     ovs-vswitchd unix:$DB_SOCK --pidfile --detach
#     ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=6
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev
#ovs-vsctl add-port br0 dpdk0 -- set Interface dpdk0 type=dpdk
#ovs-vsctl add-port br0 dpdk1 -- set Interface dpdk1 type=dpdk
ovs-vsctl set-controller br0 tcp:192.168.109.230:6633

