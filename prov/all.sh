#!/bin/bash

hostnamectl set-hostname ${PACKER_BUILD_NAME}.${DOMAIN}
echo ${ROOT_NEW_PASS} |passwd --stdin root
useradd ${OCP_USER}
echo ${OCP_PASS} |passwd --stdin ocp_admin

# override dhcp dns provider
cat <<EOF > /etc/dhclient-${NETWORK_IFC}
supersede domain-name-servers ${DNSIP};
prepend domain-search "${DOMAIN}";
EOF
systemctl restart network

# help kubernetes make accurate guarantees
# https://docs.openshift.org/latest/admin_guide/overcommit.html#disabling-swap-memory
swapoff -a

