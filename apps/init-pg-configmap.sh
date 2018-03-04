#!/usr/bin/env bash

WORKSPACE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Generate unique SSH keys"
mkdir -p ${WORKSPACE}/keys
ssh-keygen -f ${WORKSPACE}/keys/id_rsa -t rsa -N ''
ssh-keygen -t rsa -f ${WORKSPACE}/keys/ssh_host_rsa_key -N ''
ssh-keygen -t ecdsa -f ${WORKSPACE}/keys/ssh_host_ecdsa_key -N ''
ssh-keygen -t ed25519 -f ${WORKSPACE}/keys/ssh_host_ed25519_key -N ''
cp ${WORKSPACE}/keys/id_rsa.pub ${WORKSPACE}/keys/authorized_keys

echo "Create secret from SSH keys"
oc create secret generic sshd-secrets\
    --from-file=ssh-host-rsa=${WORKSPACE}/keys/ssh_host_rsa_key \
    --from-file=ssh-host-ecdsa=${WORKSPACE}/keys/ssh_host_ecdsa_key \
    --from-file=ssh-host-ed25519=${WORKSPACE}/keys/ssh_host_ecdsa_key

echo "Create pgconf ConfigMap from pgconf files for postgres"
oc create configmap pgconf \
    --from-file=pgconf=${WORKSPACE}/pgconf/postgresql.conf \
    --from-file=pghba=${WORKSPACE}/pgconf/pg_hba.conf \
    --from-file=setup=${WORKSPACE}/pgconf/setup.sql \
    --from-file=pgbackrest=${WORKSPACE}/pgconf/pgbackrest.conf \
    --from-file=sshdconf=${WORKSPACE}/pgconf/sshd_config \
    --from-file=sshauth=${WORKSPACE}/keys/authorized_keys

echo "Create pgpoolconf ConfigMap from pgpool files for pgpool"
oc create configmap pgpoolconf \
    --from-file=pgpool=${WORKSPACE}/pgpool/pgpool.conf \
    --from-file=poolhba=${WORKSPACE}/pgpool/pool_hba.conf \
    --from-file=poolpasswd=${WORKSPACE}/pgpool/pool_passwd

echo "cleanup keys"
rm -Rf ${WORKSPACE}/keys
