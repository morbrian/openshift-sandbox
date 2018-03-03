# Application Sandbox

This document describes how to create some useful sandbox application in OpenShift.


## Simple Volume Provisioning

It is worth investing some time to plan out and document the disk space needed for the cluster. 
Although implementing a robust shared storage solution is worth while for medium to large installations,
it is not necessary for our sandbox examples.

Our sandbox examples could easily be reconfigured with an even simpler storage configuration,
or skip persistence entirely, however we opted to keep things interesting by requiring a bit of simple storage.

NFS is a cheap simple option we use for some of the examples, but it is also highly unreliable for certain types 
of applications, and particularly bad for databases applications.

Instead of using NFS, we will provision our storage volumes directly on specific nodes, and then use node-selectors
to pin applications to the correct node to access the locally provisioned data.

Again, it's better to fully plan this out, but for our sandbox purposes we have enough space under /var
on the nodes, so we'll go ahead and just use that space to get started.

1. Create an appdata folder under `/var` on **ocp-node-01**:

        sudo mkdir /var/appdata

2. Prepare folders for the PostgreSQL examples (still **ocp-node-01**):

        # make the directory tree to house data the primary and replica containers
        sudo mkdir -p /var/appdata/sandbox/{primary,replica}/{data,wal,log,backup,backrestrepo}

3. Change permissions so the container will have sufficient access to the data folders.

        # change ownership/group to root (group would be nfsnobody if we used NFS)
        sudo chown -R root:root /var/appdata
        
        # limit read/write access to users in group
        sudo chmod -R 770 /var/appdata
        
        # assign SELinux attribute to give processes in a container access to these folders
        sudo chcon -Rt svirt_sandbox_file_t /var/appdata/sandbox/{primary,replica}/{data,wal,log,backup,backrestrepo}


## Load Sandbox Templates

The default OpenShift install includes many templates for a variety of application purposes. These templates
can be browsed and chosen from when adding to a project.

New custom templates can also be added to the list of available templates to choose from. Any template added
to the `openshift` namespace will be available to browse when adding to a project.

The user adding templates must have privileges to add items to the `openshift` namespace.

1. Run any or all of the `init-*-templats.sh` scripts to load some additional templates.

        # custom templates based on the crunchy-data container suite
        bash init-pg-templates.sh


## Sample Project

1. Use [web-console] to create new project

    1. "Create Project" button in top right of web console.

        1. Sample name: "sandbox"
        1. Conventions: 
            * all lower-case
            * use same name for "Name" and "Display Name"
            * "Description" is optional
            * Create configmap: Requires Command line.
        
    * Commandline Alternative:
    
            oc new-project sandbox


## CrunchyData PostgreSQL 
        
1. Using switch to created `sandbox` project using `oc` then load configmap for PostgreSQL: 

        oc project sandbox    
        bash init-pg-configmap.sh
        
2. Use [web-console], add to project, browse catalog for 'pg-secrets'

    * default parameters are fine, feel free to change if desired.
    * password is generated, actual value can be discovered by viewing the secret after creation.

3. Create storage volumes for primary database: In web-console, add to project, browse catalog for 'pg-cluster-vols'

    *This step requires a user with cluster-admin privileges.*

    * NAMESPACE: change to name of project
    * PG_MODE: primary
    * XXX_PV_PATH
        * assumes node-locked postgres pod
        * assumes the path exists on node
        * Convention: /appdata/<namespace>/<mode>/purpose
        * Example: /var/appdata/sandbox/primary/data
    * XXX_SIZE
        * assumes appropriately sized physical volumes
        * remember these numbers, used again when creating primary instance.

4. Create storage volumes for replica database: In web-console, add to project, browse catalog for 'pg-cluster-vols'

    *This step requires a user with cluster-admin privileges.*

    * NAMESPACE: change to name of project
    * PG_MODE: replica
    * XXX_PV_PATH
        * assumes node-locked postgres pod
        * assumes the path exists on node
        * Convention: /appdata/<namespace>/<mode>/purpose
        * Example: /var/appdata/sandbox/replica/data
    * XXX_SIZE
        * assumes appropriately sized physical volumes
        * remember these numbers, used again when creating replica.

5. Create PostgreSQL Primary instance: In web-console, add to project, browse catalog for 'pg-primary'

    * NAMESPACE: change to project name
    * PG_NODE: review node, make sure this is where the physical volumes are located.
    * XXX_SIZE: review sizes, this should be equal to or less than the configured volume sizes.
    * PG_RESTORE_PATH: default of 'skip' is fine, optionally change this if a pg_basebackup is available on the backup volume.

6. Using the web-console, open a terminal into the pg-primary pod just created.

    1. Move the existing pg_log directory to a new folder under /pglog, called pg-primary-log

            mv /pgdata/pg-primary/pg_log /pglog/pg-primary-log

    2. Create a soft link from the usual log directory under pgdata to the new target log location.

            ln -s /pglog/pg-primary-log /pgdata/pg-primary/pg_log

    3. Scale the container down and then scale it backup.

    4. Verify new logs are being written to the target log directory.

            ls -alh /pglog/pg-primary-log

7. Create PostgreSQL Replica instance: in web-console, add to project, browse catalog for 'pg-replica'

    * NAMESPACE: change to project name
    * PG_NODE: review node, make sure this is where the physical volumes are located.
    * XXX_SIZE: review sizes, this should be equal to or less than the configured volume sizes.

8. Using the web-console, open a terminal into the pg-replica pod just created.  

    These steps assume a sandbox environment where pgdata, pglog and pgwal are all on the same physical partition. 
    Moving the folders while the replica is running will likely fail if the physical volumes are on separate partitions, 
    and these steps will need to be done by connecting to the server via ssh to move the files.

    1. Move the existing pg_log directory to a new folder under /pglog, called pg-primary-log, and performa similar task for pgwal as the container will not perform this task automatically for replicas.

            mv /pgdata/pg-replica/pg_log /pglog/pg-replica-log
            mv /pgdata/pg-replica/pg_wal /pgwal/pg-replica-wal

    2. Create a soft link from the usual log directory under pgdata to the new target log location.

            ln -s /pglog/pg-replica-log /pgdata/pg-replica/pg_log
            ln -s /pgwal/pg-replica-wal /pgdata/pg-replica/pg_wal

    3. Scale the container down and then scale it backup.

    4. Verify new logs are being written to the target log directory.

            ls -alh /pglog/pg-replica-log
            ls -alh /pgwal/pg-replica-wal



[web-console]: https://cluster.example.com:8443  "Origin Web Console"