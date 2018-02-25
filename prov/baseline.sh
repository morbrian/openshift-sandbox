#!/bin/bash

echo perform yum update/cleanup
yum -y update
yum -y clean all
echo completed yum update/cleanup
yum -y install atomic
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sed -i -e \"s/^enabled=1/enabled=0/\" /etc/yum.repos.d/epel.repo
yum -y --enablerepo=epel install ansible pyOpenSSL
yum -y install docker-1.12.6
hostnamectl set-hostname ${NEW_HOSTNAME}

#docker requires iptables, but firewalld (which controls iptables) conflicts
systemctl enable iptables
systemctl disable firewalld

# configure docker pool
cat <<EOF > /etc/sysconfig/docker-storage-setup
VG=docker-vg
EOF

docker-storage-setup

# clean any data, should be empty already
rm -rf /var/lib/docker/*
systemctl enable docker
systemctl restart docker
