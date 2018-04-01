# OpenShift Authoriazations

The files in the `auths` folder are examples which may need to be modified for specific cluster needs.

## Prometheus Auths

Review the `namespace` in both `prometheus-sa.yaml` and `prometheus-cr-binding.yaml` before creating.

The prometheus items should be created in this order:

```
# service account identifies the account running the container
# this name should be listed in the ServiceAccountName of the container.
oc create -f prometheus-sa.yaml

# the cluster role identifies a list of actions the named role is allowed to perform.
oc create -f prometheus-cr.yaml

# the cluster role binding assigns the role permissions so a specific account,
# enabling that account to perform those actions.
oc create -f prometheus-cr-binding.yaml
```
