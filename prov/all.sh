#!/bin/bash

hostnamectl set-hostname ${PACKER_BUILD_NAME}.${DOMAIN}
echo ${ROOT_NEW_PASS} |passwd --stdin root
useradd ${OCP_USER}
echo ${OCP_PASS} |passwd --stdin ocp_admin

# override dhcp dns provider
cat <<EOF > /etc/dhcp/dhclient.conf
option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;
send host-name = gethostname();
request subnet-mask, broadcast-address, time-offset, routers,
	domain-name-servers, host-name,
	dhcp6.name-servers, dhcp6.domain-search, dhcp6.fqdn, dhcp6.sntp-servers,
	netbios-name-servers, netbios-scope, interface-mtu,
	rfc3442-classless-static-routes, ntp-servers;

supersede domain-name "${DOMAIN}";
supersede domain-name-servers ${DNSIP};
timeout 300;

EOF
systemctl restart network

# help kubernetes make accurate guarantees
# https://docs.openshift.org/latest/admin_guide/overcommit.html#disabling-swap-memory
swapoff -a

# configure ssh to be a littler more restrictive
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
cat AllowGroups sshusers >> /etc/ssh/sshd_config
groupadd -r sshusers
usermod -a -G sshusers,wheel ${OCP_USER}
