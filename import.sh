#!/bin/bash

VMS="ocp-master-01 ocp-infra-01 ocp-node-01 ocp-node-02"
NIC=eno1

for vm in ${VMS}; do
    vboxmanage import --options keepallmacs  output/vbox/${vm}/${vm}.ovf 
    vboxmanage modifyvm ${vm} --nic1 bridged --bridgeadapter1 ${NIC}
done