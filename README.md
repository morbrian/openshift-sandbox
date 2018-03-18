# OpenShift sandbox cluster on CentOS7

[web-console]: https://cluster.example.com:8443  "Origin Web Console"
[minishift]: https://www.openshift.org/minishift/ "Minishift"
[advanced-install]: https://docs.openshift.org/latest/install_config/install/advanced_install.html

Creates a simple OpenShift cluster useful for experimentation with various aspects of managing
resources across multiple nodes in a cluster. Other tools like [minishift] are great for simply
getting to know OpenShift from a software development perspective, while the virtual configuration  
described here is designed to provide a bit more hands on experience with cluster administration. 

#### Prerequisites

* Packer: tested with 1.2.0
* VirtualBox: tested with 5.2.6

## Setup

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
       
9. ??? check ??? (this was in the docs i read later but i didn't do this step)

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

 
## Logging and Metrics

We left logging and metrics out for the initial build of the VMs, now we will enable those.

### Storage Preparation

1. Add a new SCSI controller since we did not include one during initial VM creation.

```bash
vboxmanage storagectl ocp-infra-01 --name scsictl01 --add scsi
```

2. Create a new disk with the command below, it won't be attached to the controller yet.

```bash
    # creates a new 100GB virtual disk image
    vboxmanage createmedium disk --size 102400 --format VMDK --variant Standard \
        --filename /PathToVms/VirtualBox\ VMs/ocp-infra-01/ocp-infra-01-disk003.vmdk
``` 

3. Attach the new disk to the `ocp-infra-01` VM (it must be shutdown during this step).

```bash
    vboxmanage storageattach ocp-infra-01 --storagectl scsictl01 --port 1 --type hdd \
        --medium /home/bmoriarty/VirtualBox\ VMs/ocp-infra-01/ocp-infra-01-disk003.vmdk
```

4. Optionally review the configuration of `ocp-infra-01` with the new disk added.

```bash
# display info about the vm
vboxmanage showvminfo ocp-infra-01
```

5. Start `ocp-infra-01`, login via ssh and as root run `fdisk /dev/sdb`.

For flexibility and demonstration we'll create 10 partitions of about 10G each.

```bash
# create an extended partition spanning the entire disk: n, e, 1, the defaults will be start/end of disk

# create 10 new logical partitions: n, l, accept default for start and +10G for size
# after each partition, specify the type with 't' and type '8e' to specify Linux LVM type.

# the last partition may be smaller, just take the default end
# 'w' will write the partition and exit

# lsblk will list all the partitions and existing volume groups

# the following lists the commands to use in sequence and could be copy pasted into the menu:
# sed script reference: https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
  n     # new partition
  e     # extended
  1     # partition number
        # default start
        # default end
  n     # new partition
  l     # logical
        # default
  +10G  # 10gig size
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM
  n     # new partition
  l     # logical
        # default
  +10G  # 10gig size
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM  
  n     # new partition
  l     # logical
        # default
  +10G  # 10gig size
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM  
  n     # new partition
  l     # logical
        # default
  +10G  # 10gig size
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM  
  n     # new partition
  l     # logical
        # default
  +10G  # 10gig size
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM  
  n     # new partition
  l     # logical
        # default
  +10G  # 10gig size
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM
  n     # new partition
  l     # logical
        # default
  +10G  # 10gig size
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM
  n     # new partition
  l     # logical
        # default
  +10G  # 10gig size
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM
  n     # new partition
  l     # logical
        # default
  +10G  # 10gig size
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM
  n     # new partition
  l     # logical
        # default
        # last one default to remaining space
  t     # change type
        # default to partition just created
  8e    # specify Linux LVM
  w     # write changes
  q     # quit
EOF
```

6. Identify the new partitions as volumes

```bash
pvcreate /dev/sdb{5,6,7,8,9,10,11,12,13,14}
```

7. Create separate volumes for logging and metrics.

Note that in our sandbox setup we will still lump all the data onto the same virtual disk,
however in production one might want to use separate separate physical disks with fast IO characteristics
in order to reduce the risk of IO bounded problems during high volume logging events. 

```bash
vgcreate fastio01 /dev/sdb{5,6}  # start with 2 partitions worht 20G for logging
vgcreate fastio02 /dev/sdb7  # start with single 10G partition for metrics

lvcreate --name ocp_logging --size 10G fastio01
lvcreate --name ocp_logging_ops -l 100%FREE fastio01
lvcreate --name ocp_metrics -l 100%FREE fastio02
```

8. Indicate xfs format.

```bash
mkfs.xfs /dev/mapper/fastio01-ocp_logging
mkfs.xfs /dev/mapper/fastio01-ocp_logging_ops
mkfs.xfs /dev/mapper/fastio02-ocp_metrics

```

9. Create mount points.

```bash
mkdir -p /ocp/logging /ocp/metrics /ocp/logging-ops
```

10. Edit `/etc/fstab` with the new mounts, so they boot at start up.

```bash
/dev/mapper/fastio01-ocp_logging          /ocp/logging          xfs     defaults        0 0
/dev/mapper/fastio01-ocp_logging_ops      /ocp/logging-ops      xfs     defaults        0 0
/dev/mapper/fastio02-ocp_metrics          /ocp/metrics          xfs     defaults        0 0
```

11. Mount the volumes, also verifies fstab configuration.

```bash
mount -a
```

12. Configure file permissions on the newly mounted volumes.

```bash
chown -R root:root /ocp
chmod 770 /ocp/{logging,logging-ops,metrics}
chmod 750 /ocp
 
# configure selinux permissions for container access
chcon -Rt svirt_sandbox_file_t /ocp/{logging,logging-ops,metrics}
```

11.  Our final storage prep step, we need to configure the persistent volumes.

The PV descriptors are included under the `openshift-sandbox/infra` in this repository.

```bash
oc create -f infra/logging-es-ops-pv.yaml
oc create -f infra/logging-es-pv.yaml
oc create -f infra/metrics-pv.yaml
```

## Install Logging/Metrics

0. Here's a few requirements I ran into while trying to rung the metrics/logging install.

The ansible **control node** is the `ocp-infra-01` node, and it requires a few additional tools that
might have been installed in the pre-install except we had logging/metrics disabled at that point,
so we add thos tools now on infra.

````bash
# needed htpasswd on infra node (was already on master), found in httpd-tools
sudo yum install httpd-tools

# needed keytool on infra node only (found in openjdk)
sudo yum install java-1.8.0-openjdk
````

1. Log into ocp-infra-01 and run each of the following:

```bash
ansible-playbook -i ocp/hosts ./openshift-ansible/playbooks/openshift-logging/config.yml
ansible-playbook -i ocp/hosts ./openshift-ansible/playbooks/openshift-metrics/config.yml
```

The above will end up failing and we will need to do some manual intervention.

* Needed to give logging deploy privileges to logging project

```bash
oc policy add-role-to-user edit system:serviceaccount:logging:deployer -n logging
```

* Needed to edit deploymens for logging-es-data and logging-es-ops-data to change container name.

````bash
openshift/oauth-proxy:v1.0.0   instead of openshift/origin-oauth-proxy:v1.0.0
````

Then redeployed both containers.

2. Additional fixup steps:

* Quotas for metrics especially and also logging required way too much memory for our small cluster,
so lowered all quotas to under 1GB, and 512MB in many cases.

* Metrics never really worked, but not important, so scaled it down and can debug later.


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
        
Add an address line to support the wildcard domain for the cluster

        address=/cluster.example.com/192.168.1.200
        # where the above is the cluster domain and the ip address of ocp-infra-01 


TODO: probably better to specify the interface... but working on issues.

TODO: if using the interface, consider also specifying this setting with the NIC identifier no-dhcp-interface=<ifcx>

TODO: I generally can't get dnsmasq to start correctly because the interface is not ready yet.





