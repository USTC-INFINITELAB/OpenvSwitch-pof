set -e

## install ovs-dpdk
export HOME=$HOME
export DPDK_DIR=$HOME/dpdk-16.07
cd $DPDK_DIR

## dpdk configuration
export DPDK_TARGET=x86_64-native-linuxapp-gcc
export DPDK_BUILD=$DPDK_DIR/$DPDK_TARGET
#rm -r x86_64-native-linuxapp-gcc
if [ ! -d $HOME/dpdk-16.07/x86_64-native-linuxapp-gcc ]
then
make install T=$DPDK_TARGET DESTDIR=install
fi

## for i40e driver, should compile it when first run
#make install T=$DPDK_TARGET DESTDIR=install
# For IVSHMEM, Set `export DPDK_TARGET=x86_64-ivshmem-linuxapp-gcc`

cd $HOME
export OVS_DIR=$HOME/OpenvSwitch-pof/
cd $OVS_DIR
#./boot.sh                           ## run once when first run

## configure, can use '-march=native' accelerate ovs-pof packet processing
#./configure --with-dpdk=$DPDK_BUILD
# ./configure CFLAGS="-g -O0" --with-dpdk=$DPDK_BUILD  ## way1: use 'dpdk', with lower performance
./configure CFLAGS="-g -O2 -march=native" --with-dpdk=$DPDK_BUILD  ## way2: use 'dpdk' and 'native' to accelerate processor, decreases hash times. with higher performance

## compilation and install
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

# for i40e, run only once
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

##  IPL211, sfp for bigtao test (high speed), ethx for ostinato test (low speed)
./tools/dpdk-devbind.py --bind=igb_uio 0000:05:00.0  # sfp R1
./tools/dpdk-devbind.py --bind=igb_uio 0000:05:00.1  # sfp R2
./tools/dpdk-devbind.py --bind=igb_uio 0000:05:00.2  # sfp R3
#./tools/dpdk-devbind.py --bind=uio_pci_generic 0000:07:00.0 # eth1
#./tools/dpdk-devbind.py --bind=uio_pci_generic 0000:07:00.1 # eth2
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
#     ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,0"  ## for multiple threads across cores.
#     ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,1024"
#     ovs-vswitchd unix:$DB_SOCK --pidfile --detach
#     ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=6
ovs-appctl vlog/set ANY:ANY:INFO
ovs-appctl vlog/set ofproto:ANY:dbg
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev

#ovs-vsctl set-controller br0 tcp:192.168.109.209:6666
ovs-vsctl add-port br0 dpdk0 -- set Interface dpdk0 type=dpdk
ovs-vsctl add-port br0 dpdk1 -- set Interface dpdk1 type=dpdk
ovs-vsctl add-port br0 dpdk2 -- set Interface dpdk2 type=dpdk
#ovs-ofctl show br0
sleep 1s

## set datapath-id of ovs, must be 8B decimal number, cannot omit zeros.
ovs-vsctl set bridge br0 other-config:datapath-id=0000000000000002

#ovs-appctl -t ovs-vswitchd exit
#ovs-vswitchd --pidfile

grep HugePages_ /proc/meminfo   #获取大页信息
