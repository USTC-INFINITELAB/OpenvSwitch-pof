set -e

## install ovs-dpdk
export HOME=$HOME
export DPDK_DIR=$HOME/dpdk-16.07
cd $DPDK_DIR

## dpdk configuration
export DPDK_TARGET=x86_64-native-linuxapp-gcc
export DPDK_BUILD=$DPDK_DIR/$DPDK_TARGET

if [ ! -d $HOME/dpdk-16.07/x86_64-native-linuxapp-gcc ]
then
make install T=$DPDK_TARGET DESTDIR=install
fi

cd $HOME
export OVS_DIR=$HOME/OpenvSwitch-pof/
cd $OVS_DIR

## run once only when first when the project
#./boot.sh                           

## configure, can use '-march=native' accelerate ovs-pof packet processing
./configure CFLAGS="-g -O0" --with-dpdk=$DPDK_BUILD                      ## w/o acceleration flag
# ./configure CFLAGS="-g -O2 -march=native" --with-dpdk=$DPDK_BUILD      ## w/ acceleration flag

## compilation and install
make -j24
make install

## configure the hugepages
echo 'vm.nr_hugepages=2048' > /etc/sysctl.d/hugepages.conf
sysctl -w vm.nr_hugepages=2048
#grep HugePages_ /proc/meminfo   
if [ ! -d /dev/hugepages ]
then
  mkdir /dev/hugepages
fi
mount -t hugetlbfs none /dev/hugepages

cd $DPDK_DIR
modprobe uio_pci_generic

##  driver binding examples
./tools/dpdk-devbind.py --bind=uio_pci_generic 0000:07:00.0 # eth1
./tools/dpdk-devbind.py --bind=uio_pci_generic 0000:07:00.1 # eth2
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
     ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,1024"
#     ovs-vswitchd unix:$DB_SOCK --pidfile --detach
#     ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=6
ovs-appctl vlog/set ANY:ANY:INFO
ovs-appctl vlog/set ofproto:ANY:dbg
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev

#ovs-vsctl set-controller br0 tcp:192.168.109.209:6666
ovs-vsctl add-port br0 dpdk0 -- set Interface dpdk0 type=dpdk
ovs-vsctl add-port br0 dpdk1 -- set Interface dpdk1 type=dpdk
#ovs-ofctl show br0
sleep 1s

## set datapath-id of ovs, must be 8B decimal number, cannot omit zeros.
ovs-vsctl set bridge br0 other-config:datapath-id=0000000000000001

#ovs-appctl -t ovs-vswitchd exit
#ovs-vswitchd --pidfile

grep HugePages_ /proc/meminfo  
