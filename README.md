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
        
6. Log into ocp-infra-01

        ssh ocp_admin@ocp-infra-01

7. Use the script in ocp_admin's to copy the public `ssh_id` to the other servers to support paswordless login.

        ./push-ssh-id.sh
        
        # it will generate key
        # hit enter twice (no passphrase)
        # accept default file (just enter)
        #
        # will connect to each  host
        # enter 'yes' to connect for first time
        # enter ocp_admin password to authenticate
        
8. Ready to install OpenShift, see docs for details or skip to next step to start running scripts.

    * https://docs.openshift.org/latest/install_config/install/advanced_install.html#install-config-install-advanced-install
    
    * https://docs.openshift.org/latest/install_config/install/advanced_install.html#running-the-advanced-installation-system-container

9. As `ocp_admin` user on ocp-infra-01, verify prerequisites are met.

        ansible-playbook -i /home/ocp_admin/ocp/hosts /home/ocp_admin/openshift-ansible/playbooks/prerequisites.yml
       
9. ??? check ???

        atomic install --system \
            --storage=ostree \
            --set INVENTORY_FILE=/home/ocp_admin/ocp/hosts \
            --set PLAYBOOK_FILE=/usr/share/ansible/openshift-ansible/playbooks/openshift-checks/pre-install.yml \ 
            --set OPTS="-v" \ 
            docker.io/openshift/origin-ansible:v3.6
        
10. As user `ocp_admin` on ocp-infra-01, run install as a system container:

         atomic install --system \
            --storage=ostree \
            --set INVENTORY_FILE=/home/ocp_admin/ocp/hosts \
            docker.io/openshift/origin-ansible:v3.6    

11. When this completes??? 

12. Log into ocp-master-01 with ssh to add yourself as an OpenShift user.

        htpasswd -B /etc/origin/master/htpasswd yourusername

13.  Verify the new user by logging into the [web-console](web-console)


## Next Steps

At this point, the cluster is set up and some decisions should be made about how it should be managed.  This section
provides some reasonable next steps by making some assumptions about the cluster purpose.

* Assumes cluster is an education sandbox for exploring origin capabilities.

* Assumes your user will need admin privileges to perform many of the tests.


1. Give your user admin privileges by logging into ocp-master-01 to run this at commandline:

        /usr/local/bin/oc adm policy add-cluster-role-to-user cluster-admin youruser
        
    Now when logging into [web-console] other projects will be viewable, and your user can manage all objects such as persistent volumes and listing nodes.

2. The `oc` binary is available for any platform, optionally install it on another system.

    1. A link for where to find the `oc` binary can be found on the [web-conole] by going to the help `?` and choosing *Command Line Tools*, 
    then find the release compatible with the installed server version. 
    
    Right now, the latest for 3.6 is: https://github.com/openshift/origin/releases/tag/v3.6.1
    
    1. Download and extract the client-tools archive for your platform, putting the `oc` binary in your PATH.
    
    1. Login to cluster using command:  oc login https://ocp-master-01.example.com:8443
    
    1. Try some example commands to verify the user has cluster admin and basic privileges:
    
            # list nodes in cluster
            oc get node
            
            # new project
            oc new-project newprojectname


## Supporting Services

A few items should exist outside the OpenShift cluster.

### DNS

Using `dnsmasq` available on most modern linux systems is probably the simplest option. `dnsmasq` supports editing your
local hosts file to add records, so unless you're trying to configure a production DNS configuration, this will be
simplest for sandbox testing.

Reference: https://help.ubuntu.com/community/Dnsmasq

The following steps assume Ubuntu as an example system.

We assume the target workstation gets its ip address from a DHCP server and include related configuration.

1. Assuming a network or somewhere you have some control over an existing DHCP server,
such as on a home cable modem router. 

Edit the router to provide the MAC address of the planned DNS server and configure it to always provide that
MAC with the same IP address.


2. Create or edit the file `/etc/dhcp/dhclient.conf`.

* Replace `example.com` with the planned domain.

* Replace `192.168.1.101` with the planned DNS server IP address.


        option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;
        send host-name = gethostname();
        request subnet-mask, broadcast-address, time-offset, routers,
            domain-name-servers, host-name,
            dhcp6.name-servers, dhcp6.domain-search, dhcp6.fqdn, dhcp6.sntp-servers,
            netbios-name-servers, netbios-scope, interface-mtu,
            rfc3442-classless-static-routes, ntp-servers;
        
        supersede domain-name "example.com";
        prepend domain-name-servers 192.168.1.101;
        timeout 300;
        

3. Edit file `/etc/dnsmasq.conf`

Edit this file, specifying the IP DNS should listen on.


        listen-address=192.168.1.101,127.0.0.1


TODO: probably better to specify the interface... but working on issues.
TODO: if using the interface, consider also specifying this setting with the NIC identifier no-dhcp-interface=<ifcx>
TODO: I generally can't get dnsmasq to start correctly because the interface is not ready yet.





[web-console]: https://cluster.example.com:8443  "Origin Web Console"
