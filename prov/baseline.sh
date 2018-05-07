#!/bin/bash

echo perform yum update/cleanup
yum -y update
yum -y clean all
echo completed yum update/cleanup
yum -y install atomic
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sed -i -e \"s/^enabled=1/enabled=0/\" /etc/yum.repos.d/epel.repo
yum -y --enablerepo=epel install ansible pyOpenSSL

# start firwalld to be sure its up before docker
# documentation says if firewalld is restarted/reloaded, then docker must also be restarted
systemctl enable firewalld
systemctl start firewalld

yum -y install docker-1.13.1
yum -y install python-rhsm-certificates
hostnamectl set-hostname ${NEW_HOSTNAME}


# configure docker pool
cat <<EOF > /etc/sysconfig/docker-storage-setup
VG=docker-vg
EOF

docker-storage-setup

# clean any data, should be empty already
rm -rf /var/lib/docker/*
systemctl enable docker
systemctl restart docker

