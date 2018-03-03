#!/usr/bin/env bash

WORKSPACE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Create ConfigMap from pgconf files"
oc create configmap pgconf \
    --from-file=pgconf=${WORKSPACE}/pgconf/postgresql.conf \
    --from-file=pghba=${WORKSPACE}/pgconf/pg_hba.conf \
    --from-file=setup=${WORKSPACE}/pgconf/setup.sql \
    --from-file=pgbackrest=${WORKSPACE}/pgconf/pgbackrest.conf
