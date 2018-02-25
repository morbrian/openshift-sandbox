# Packer build for small OpenShift cluster on CentOS7

1. Build the baseline VM template from CentOS 7.4 iso:


        packer build centos7-vbox-iso.json


2.  (Recommended) Set local environment to override some settings in cluster:


        export MCM_SSH_PASS=betterpass      # will become new root password
        export MCM_OCP_PASS=superpass       # will become ocp_admin password
        export MCM_OCP_DOMAIN=example.com   # will become cluster domain  
        export MCM_OCP_DNSIP=192.168.1.1    # set to DNS server that knows how to resolve cluster hostnames
        export MCM_OCP_NETWORK_IFC=enp0s3   # interface name inside the vm


3. Build the four cluster VMs (master, infra, node-01, node-02):


        packer build -parallel=false -force \
            -var "root_new_pass=${MCM_SSH_PASS}" \
            -var "ocp_pass=${MCM_OCP_PASS}" \
            -var "domain=${MCM_OCP_DOMAIN}" \
            -var "dnsip=${MCM_OCP_DNSIP}" \
            -var "network_ifc=${MCM_OCP_NETWORK_IFC}" \
            centos7-vbox-ovf.json


4. Import all of the VMs just created:


        ./import.sh
        

5. Next steps...
        


