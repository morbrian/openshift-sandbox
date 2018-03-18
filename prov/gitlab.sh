#!/bin/bash

sudo systemctl stop iptables
sudo systemctl disable iptables
sudo systemctl enable firewalld
sudo systemctl start firewalld

sudo yum install -y curl policycoreutils-python openssh-server
sudo systemctl enable sshd
sudo systemctl start sshd
sudo firewall-cmd --permanent --add-service=http
sudo systemctl reload firewalld

sudo yum install postfix
sudo systemctl enable postfix
sudo systemctl start postfix

curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash

sudo EXTERNAL_URL="http://gitlab.lionel.io" yum install -y gitlab-ee


