OpenvSwitch-pof (OVS-POF)
============

OpenvSwitch-pof is extended to support protocol oblivious forwarding (POF) based on OVS-DPDK 2.6.9, which makes OVS can match protocol fields in ```<offset, length>``` tuple way with more flexibility. And the DPDK we used is version 16.07, which can download it at [dpdk.org](dpdk.org).

In this stage, the OVS-POF only supports to connect with the remote controller to configure the flow entries, while other cli command can still works such as ```dump-flows```. The controller we developed is [ONOS](), which is POF-enabled.

How to run?
---------------------
The OVS-POF follows the install steps of OVS. Start with OVS-DPDK, please read [INSTALL.DPDK.md]. For ease of use, we create two scripts (```setup.sh``` and ```unsetup.sh```) to automatically install or uninstall the OVS-POF. 

After the DPDK confifuration (i.e., driver binding, hugepages), then it's easy for us in later running with the scripts.
```
# run the OVS-POF
sudo ./setup.sh

# connect the ONOS, port 6643
sudo ovs-vsctl set-controller br0 tcp:10.0.0.2:6643

# kill the OVS-POF
sudo ./unsetup.sh
```