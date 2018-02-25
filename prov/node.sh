#!/bin/bash

# define how kernel handles over committed resources
# https://docs.openshift.org/latest/admin_guide/overcommit.html#kernel-tunable-flags
sysctl -w vm.overcommit_memory=1
sysctl -w vm.panic_on_oom=0
