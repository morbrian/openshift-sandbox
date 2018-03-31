# Application Sandbox

[web-console]: https://cluster.example.com:8443  "Origin Web Console"

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
        sudo mkdir -p /var/appdata/sandbox/{primary,replica}/{data,wal,log,backup,backrestrepo,metrics}

3. Change permissions so the container will have sufficient access to the data folders.

        # change ownership/group to root (group would be nfsnobody if we used NFS)
        sudo chown -R root:root /var/appdata
        
        # limit read/write access to users in group
        sudo chmod -R 770 /var/appdata
        
        # assign SELinux attribute to give processes in a container access to these folders
        sudo chcon -Rt svirt_sandbox_file_t /var/appdata/sandbox/{primary,replica}/{data,wal,log,backup,backrestrepo,metrics}


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

    TODO: later realized this can be avoid by just setting the pg_log path in postgresql.conf instead

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

 
 ### Verify PostgreSQL Replication
 
 1. Use `oc rsh` to connect to database with psql and create sample table.
 
        oc rsh $(oc get pod --output=name |grep primary) \
            psql -Usandbox -dsandbox -c "create table sample (id integer, name varchar, details varchar)"
        oc rsh $(oc get pod --output=name |grep primary) \
            psql -Usandbox -dsandbox -c "insert into sample (id, name, details) values (1, 'apple', 'red fruit')"

2. Verify data is present in primary.

         oc rsh $(oc get pod --output=name |grep primary) \
            psql -Usandbox -dsandbox -c "select * from sample"
            
3. Verify data is present in replica.

         oc rsh $(oc get pod --output=name |grep replica) \
            psql -Usandbox -dsandbox -c "select * from sample"


### Verify PostgreSQL pg-backrest integrity

As we have a replica, it would be best to perform the backup from there to save cpu and io on the master.

The instructions below demonstrate using the primary. -- we'll update later with the better replica option.

1. Put some data in the database.

        oc rsh $(oc get pod --output=name |grep primary) \
            psql -Usandbox -dsandbox -c "insert into sample (id, name, details) values (2, 'banana', 'yellow fruit')"

2. Run a backup with pgbackrest command. 

        # connect to container in new bash shell (the new shell configures user id as `postgres`)
        oc rsh $(oc get pod --output=name |grep primary) bash
        
        # run initial backup
        pgbackrest --stanza=db --log-level-console=info backup
        
        # review backup
        pgbackrest info
        
3. Make some changes to the data in database.

        psql -Usandbox -dsandbox -c "delete from sample where id < 2; update sample set name='lemon' where id=2"
        
        # verify changes
        psql -Usandbox -dsandbox -c "select * from sample"
        
4. Scale down primary and replica using [web-console]

    Commandline Alternative:
    
            oc scale dc pg-replica --replicas=0
            oc scale dc pg-primary --replicas=0

5. Perform a Restore (Reference: https://github.com/CrunchyData/crunchy-containers/blob/master/docs/backrest.adoc)

    1. Log into ocp-node-01 with ssh and delete all data from primary and replica:
    
        **Note how this will also remove the `pg_wal` and `pg_log` soft links that were configured earlier**
    
            ssh ocp_admin@ocp-node-01
            sudo find /var/appdata/sandbox/{primary,replica}/{data/pg-primary,wal} -mindepth 1 -delete
            
    2. Use [web-console], add to project, select pg-backrest-restore template.
    
        * Change namespace to the project name (ie. sandbox)
        * Expect Job to complete successfully.
        
    3. Use [web-console] terminal to review restore.
    
            psql -Usandbox -dsandbox -c "select * from sample"
            
       Expect data to be in same state we left it in before deleting the files.

    4. Repair primary configuration of `pgwal` and `pglog`.
    
        **If physical storage is not on same partition, this must be done with postgresql stopped**
    
            # pglog
            mv /pgdata/pg-primary/pg_log/* /pglog/pg-primary-log
            rmdir /pgdata/pg-primary/pg_log
            ln -sf /pglog/pg-primary-log /pgdata/pg-primary/pg_log
            
            # pgwal
            mv /pgdata/pg-primary/pg_wal /pgwal/pg-primary-wal
            ln -sf /pgwal/pg-primary-wal /pgdata/pg-primary/pg_wal

    5. Scale up replica, use [web-console] terminal to check replicated data.
    
            psql -Usandbox -dsandbox -c "select * from sample"
    
    6. Repair replica configuration of `pgwal` and `pglog`.
    
        **If physical storage is not on same partition, this must be done with postgresql stopped**
    
            # pglog
            mv /pgdata/pg-replica/pg_log/* /pglog/pg-replica-log
            rmdir /pgdata/pg-replica/pg_log
            ln -sf /pglog/pg-replica-log /pgdata/pg-replica/pg_log
            
            # pgwal
            mv /pgdata/pg-replica/pg_wal /pgwal/pg-replica-wal
            ln -sf /pgwal/pg-replica-wal /pgdata/pg-replica/pg_wal
            
## Additional Restore Scenarios

The default run command in the crunchdata pgbackrest-restore container is a bit limited and hard
to configure through the provided environment variables.

Using the provided container but giving arbitrary commandline access make the restore process
much more flexible and provides more insight into the process.

This repository provides `pg-backrest-restore-interactive.yaml` to help with other kinds of
pgbackrest retores. The container runs in privileged mode, and requires the restore to be
run as root in order to modify file permissions appropriately.

1. Prepare the *Security Context Constraints* so that the container can run.

Change the `sandbox` namespace to the actual namespace where pg-primary is running,
or at least change it to the project where the backrest-restore will be run from.

``` 
oc create serviceaccount backrest-restore -n sandbox
oc adm policy add-scc-to-user privileged -n sandbox -z backrest-restore
```

2. Create an instance of the `pg-backrest-restore-interactive` template in the target project.

It's worth making sure the backrest version matches the crunchy container version in CCP_IMAGE_TAG.

``` 
oc new-app pg-backrest-restore-interactive -p NAMESPACE=pg-primary -p PG_NODE=ocp-node-01.example.com -p CCP_IMAGE_TAG=centos7-10.3-1.8.1
```

3. Connect to the now running interactive container.

``` 
oc rsh pg-backrest-restore-interactive
```

4. Run an appropriate backup.

If doing PITR testing, it would be useful to run this command to get the exact date just before
corrupting the database to make the restore target easier. Otherwise, in a real world scenario
this date string shows the right format, but some guesswork is needed to pick the right time
before the corruption incident occured.

``` 
select current_timestamp;
```

Example PITR restore command (use this if you know an approximate target time when the state was good)

``` 
pgbackrest --config=/pgconf/pgbackrest.conf --stanza=db --log-level-console=info --delta --type=time "--target=2018-03-31 20:47:21.376193+00" restore
```

Example FULL restore command (use this if the entire database partition was lost, requires directory to be empty):

``` 
pgbackrest --config=/pgconf/pgbackrest.conf --stanza=db --log-level-console=info restore
```    

Example DELTA restore command (use this to save time when most of the database is ok by some files are corrupt)

``` 
pgbackrest --config=/pgconf/pgbackrest.conf --stanza=db --log-level-console=info --delta restore
```    

5. Fix file permissions

Everything will be owned by user `26`, but change to the correct ID of the project running postgres.

``` 
chown -R 1000100000:root /pgdata/pg-primary/*
```    
    
6. Delete pg-backrest-restore-interactive pod.

7. Scale up PostgreSQL deployment.

After start up, the PITR option will have paused wal replay and the following will likely be required.

``` 
select pg_wal_replay_resume();
```

8. Assuming the data looks ok, run a backup now to ensure the next restore will target this point.

``` 
pgbackrest --stanza=db --log-level-console=info backup
```
    
## Crunchy Metrics for PostgreSQL

[crunchy-metrics]: https://github.com/CrunchyData/crunchy-containers/blob/master/docs/metrics.adoc

CrunchyData Metrics provides a configuration of Prometheus and Grafana to support monitoring
the performance of a PostgreSQL cluster. See [crunchy-metrics] for additional details.

1. A subfolder for metrics data was created during *Simple Volume Provisioning* at 
`/var/appdata/sandbox/primary/metrics`, and the crunchy-metrics *PersistentVolume* template called was imported when we
ran  `init-pg-templates.sh`. The next steps assume we are starting with those steps already done,
along with the sandbox project and PostgreSQL already prepared.

2. Create storage volumes for primary database: In web-console, add to project, browse catalog for 'crunchy-metrics-vols'
   
       *This step requires a user with cluster-admin privileges.*
   
       * NAMESPACE: change to name of project
       * XXX_PV_PATH
           * assumes node-locked postgres pod
           * assumes the path exists on node
           * Convention: /appdata/<namespace>/<mode>/purpose
           * Example: /var/appdata/sandbox/primary/metrics
       * XXX_SIZE
           * assumes appropriately sized physical volumes
           * remember these numbers, used again when creating primary instance.

3. Create PostgreSQL Primary instance: In web-console, add to project, browse catalog for 'crunchy-metrics'
   
       * NAMESPACE: change to project name
       * PG_NODE: review node, make sure this is where the physical volumes are located.
       * XXX_SIZE: review sizes, this should be equal to or less than the configured volume sizes.

4. Validation Steps

    1. Currently need to create routes to grafana and prometheus services
        
        crunchy-prometheus: 9090
        
        crunchy-grafana: 3000
  
    2. Earlier steps glossed over the metrics related environment variables when configuring the
    `crunchy-collect` container in the pg-primary setup. These need to be reviewed and updated at this point.
    
        * PROM_GATEWAY
        
        * NODE_EXPORTER_URL
        
        * POSTGRES_EXPORTER_URL
        
        * DATA_SOURCE_NAME
  
    3. Connect to grafana and configure data source, and load crunchy dashboard,
    see [crunchy-metrics] for how to do this.


## Sonarqube

1. Create template instances in project **devops**

``` 
oc create -n openshift templates/sonarqube-secrets.yaml
oc create -n openshift templates/sonarqube.yaml
```

2. Create instance of secrets template in gui, view password after creation.

3. Use generated password and `sonar` username to create database and role.

We created a general purpose shared `sandbox` PostgreSQL cluster for this purpose.

```
CREATE ROLE sonar WITH PASSWORD 'changeit';
ALTER ROLE "sonar" WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION 
    NOBYPASSRLS CONNECTION LIMIT 50;
CREATE DATABASE sonar WITH OWNER = sonar ENCODING = 'UTF8' TABLESPACE = pg_default 
    LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' CONNECTION LIMIT = -1 TEMPLATE template0;
```
 
4. Give sonarqube appropriate privileges... 

``` 
oc create serviceaccount sonarqube -n devops
oc adm policy add-scc-to-user privileged -n devops -z sonarqube
```
  
5. Create instance of Sonarqube in `devops` from template.

Use JDBC URL = jdbc:postgresql://pg-primary.sandbox/sonar

6. Initial default login is admin / admin
