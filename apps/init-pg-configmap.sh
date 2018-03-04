#!/usr/bin/env bash

WORKSPACE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Create pgconf ConfigMap from pgconf files for postgres"
oc create configmap pgconf \
    --from-file=pgconf=${WORKSPACE}/pgconf/postgresql.conf \
    --from-file=pghba=${WORKSPACE}/pgconf/pg_hba.conf \
    --from-file=setup=${WORKSPACE}/pgconf/setup.sql \
    --from-file=pgbackrest=${WORKSPACE}/pgconf/pgbackrest.conf

echo "Create pgpoolconf ConfigMap from pgpool files for pgpool"
oc create configmap pgpoolconf \
    --from-file=pgpool=${WORKSPACE}/pgpool/pgpool.conf \
    --from-file=poolhba=${WORKSPACE}/pgpool/pool_hba.conf \
    --from-file=poolpasswd=${WORKSPACE}/pgpool/pool_passwd

