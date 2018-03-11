#!/usr/bin/env bash

WORKSPACE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Create crunch-watch sa"
oc create -f ${WORKSPACE}/serviceaccounts/crunchy-watch-sa.json

echo "Remember to add privileges as needed, this script won't do it for you."
echo ""
echo "    oc policy add-role-to-user edit system:serviceaccount:${NAMESPACE}:crunchy-watch -n ${NAMESPACE}"
echo ""
