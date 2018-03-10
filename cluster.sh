#!/bin/bash

action=$1

VMS="ocp-master-01 ocp-infra-01 ocp-node-01 ocp-node-02"

start() {
    for vm in ${VMS}; do
        vboxmanage startvm --type headless ${vm}
    done
}

stop() {
    for vm in ${VMS}; do
        vboxmanage controlvm ${vm} acpipowerbutton
    done
}

status() 
{
    for vm in ${VMS}; do
        echo "${vm}: $(vboxmanage showvminfo ${vm} | grep State)"
    done
}

usage() {
    echo "Usage: $0 {start}stop|status|import}}"
    RETVAL="2"
}

import() {
    NIC=eno1
    for vm in ${VMS}; do
        vboxmanage import --options keepallmacs  output/vbox/${vm}/${vm}.ovf 
        vboxmanage modifyvm ${vm} --nic1 bridged --bridgeadapter1 ${NIC}
    done
}



RETVAL="0"
case "$action" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    import)
        import
        ;;
    *)
        usage
        ;;
esac

exit $RETVAL