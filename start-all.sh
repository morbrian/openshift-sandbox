#!/bin/bash

VMS="ocp-master-01 ocp-infra-01 ocp-node-01 ocp-node-02"

for vm in ${VMS}; do
    vboxmanage startvm --type headless ${vm}
done