#!/usr/bin/env bash

WORKSPACE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Loading Primary Templates"
oc create -n openshift -f ${WORKSPACE}/templates/pg-secret.yaml
oc create -n openshift -f ${WORKSPACE}/templates/pg-cluster-vols.yaml
oc create -n openshift -f ${WORKSPACE}/templates/pg-primary.yaml
oc create -n openshift -f ${WORKSPACE}/templates/pg-replica.yaml
oc create -n openshift -f ${WORKSPACE}/templates/pg-pool.yaml
oc create -n openshift -f ${WORKSPACE}/templates/pg-backrest-restore.yaml
oc create -n openshift -f ${WORKSPACE}/templates/pg-backrest-interactive.yaml

# if template needs to be reloaded, it can be force replaced:
# oc replace --force -n openshift -f templates/filename.yaml
