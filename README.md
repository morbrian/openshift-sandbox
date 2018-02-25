# Packer build for small OpenShift cluster on CentOS7

1. Build the baseline VM template from CentOS 7.4 iso:


        packer build centos7-vbox-iso.json


2.  (Recommended) Set local environment to override some settings in cluster:


        export MCM_SSH_PASS=betterpass      # will become new root password
        export MCM_OCP_PASS=superpass       # will become ocp_admin password
        export MCM_OCP_DOMAIN=example.com   # will become cluster domain  
        export MCM_OCP_DNSIP=192.168.1.1    # set to DNS server that knows how to resolve cluster hostnames


3. Build the four cluster VMs (master, infra, node-01, node-02):


        packer build -parallel=false -force \
            -var "root_new_pass=${MCM_SSH_PASS}" \
            -var "ocp_pass=${MCM_OCP_PASS}" \
            -var "domain=${MCM_OCP_DOMAIN}" \
            -var "dnsip=${MCM_OCP_DNSIP}" \
            centos7-vbox-ovf.json


4. Import all of the VMs just created:


        ./import.sh
        

5. Start all the VMs


        ./start-all.sh
        
6. 
        


## Supporting Services

A few items should exist outside the OpenShift cluster.

### DNS

Using `dnsmasq` available on most modern linux systems is probably the simplest option. `dnsmasq` supports editing your
local hosts file to add records, so unless you're trying to configure a production DNS configuration, this will be
simplest for sandbox testing.

Reference: https://help.ubuntu.com/community/Dnsmasq

1. asdfasdf